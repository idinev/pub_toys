#include <windows.h>
#include <gl/gl.h>
#include <gl/glu.h>
#include <gl/glaux.h>
#include <gl/glext.h>
#include <gl/wglext.h>
#include <olectl.h>

#include "Ultrano.h"
#include "oDraw.h"

#pragma comment(lib,"opengl32.lib")

static HWND oDraw_HWND;
static HDC hDC=0;
static HGLRC hRC=0;


int oDraw_OFFX=0,oDraw_OFFY=0;
float oDraw_OFFZ=0;
int oDraw_COLOR=0xFFFFFFFF;



#define OPENGL_MACRO(proc,proctype) proctype proc
	OPENGL_MACRO(glProgramStringARB,PFNGLPROGRAMSTRINGARBPROC);
	OPENGL_MACRO(glGenProgramsARB,PFNGLGENPROGRAMSARBPROC); 
	OPENGL_MACRO(glBindProgramARB,PFNGLBINDPROGRAMARBPROC); 
	OPENGL_MACRO(glDeleteProgramsARB,PFNGLDELETEPROGRAMSARBPROC); 
	OPENGL_MACRO(glProgramLocalParameter4fARB,PFNGLPROGRAMLOCALPARAMETER4FARBPROC); 
	OPENGL_MACRO(glProgramLocalParameter4fvARB,PFNGLPROGRAMLOCALPARAMETER4FVARBPROC);
	OPENGL_MACRO(wglSwapIntervalEXT,PFNWGLSWAPINTERVALEXTPROC);
#undef OPENGL_MACRO






//===============[[ TEXTURE LOADING ]]=================================================[[
POINT _oDraw_LastTextureSize;

int oDraw_LoadImage(const char* FileName,bool bSmooth){
	if(FileName){
		int fsize;
		void* data = uffetch(FileName,&fsize);
		if(data){
			int result=0;
			if(ustrEndsWith(FileName,".tga"))result = oDraw_LoadImageTGA(data,fsize,bSmooth);
			else if(ustrEndsWith(FileName,".jpg"))result = oDraw_LoadImageJPG(data,fsize,bSmooth);
			else if(ustrEndsWith(FileName,".bmp"))result = oDraw_LoadImageJPG(data,fsize,bSmooth);
			xfree(data);
			return result;
		}
	}
	return 0;
}

char* oDraw_DecodeJPG(const void* Data,int DataSize,int* Width,int* Height){
	if(!Data || !DataSize)return null;
	//----[ copy data ]-------------------------------------[
	// yeah, I know it's bloated. 
	// But jpegs sent here would be small anyway
	HGLOBAL hGlobal = GlobalAlloc(GMEM_MOVEABLE,DataSize);
	memcpy(GlobalLock(hGlobal),Data,DataSize);
	GlobalUnlock(hGlobal);
	//------------------------------------------------------/

	LPSTREAM pstm;
	CreateStreamOnHGlobal(hGlobal,1,&pstm);

	IPicture* PictuBaka;
	HBITMAP hBmp;
	if(OleLoadPicture( pstm, DataSize,0,IID_IPicture,(LPVOID*)&PictuBaka)){
		//trace("Cannot load image %s",fName);
		pstm->Release();
		GlobalFree(hGlobal);
		return null;
	}
	if(PictuBaka->get_Handle((OLE_HANDLE*)&hBmp)){
		PictuBaka->Release();
		pstm->Release();
		GlobalFree(hGlobal);
		return null;
	}

	BITMAP bi;
	GetObject(hBmp,sizeof(BITMAP),&bi);
	
	int wid = bi.bmWidth;
	int hei = bi.bmHeight;
	
	char* pixels = (char*)xmalloc(wid*hei*4);


	BITMAPINFOHEADER hdr1;
	memset(&hdr1,0,sizeof(hdr1));

	hdr1.biSize=sizeof(BITMAPINFOHEADER);
	hdr1.biWidth=wid;
	hdr1.biHeight=-hei;
	hdr1.biPlanes=1;
	hdr1.biBitCount=32;
	hdr1.biCompression=BI_RGB;
	hdr1.biSizeImage=wid*hei*4;

	HDC dc = CreateCompatibleDC(GetDC(0));
	GetDIBits(dc,hBmp,0,hei,pixels,(LPBITMAPINFO)&hdr1,DIB_RGB_COLORS);

	DeleteObject(hBmp);
	DeleteObject(dc);

	PictuBaka->Release();
	pstm->Release();
	GlobalFree(hGlobal);
	for(int j=wid*hei*4;j-=4;)pixels[j+3]=-1; // set alpha=1.0f;

	*Width = wid;
	*Height= hei;
	return pixels;
}

char* oDraw_DecodeTGA(const void* Data,int DataSize,int* Width,int* Height){ // does not allocate data!!!
	struct TGAHEAD{
		U8 data[12];
		U16 wid,hei;
		U8 bpp,alphabits;
		char ImageData[1];
	};
	if(!Data)return null;
	TGAHEAD* head =(TGAHEAD*)Data;
	if(head->data[0] || head->data[1] || head->data[2]!=2 || head->bpp!=32/* || head->alphabits!=0x28*/){
		prints("TGA incompatible");
		return null; // 0x28 specifies "8-bit alpha, beginning at top-left"
	}
	*Width = head->wid;
	*Height= head->hei;
	return head->ImageData;
}

int oDraw_LoadImageBGRA(void* pixels,int wid,int hei,bool bSmooth){ // pixels can be null!!
	if(wid<=0 || hei<=0)return 0;
	
	_oDraw_LastTextureSize.x = wid;
	_oDraw_LastTextureSize.y = hei;

	U32 result=0;
	glGenTextures( 1, &result);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB,result);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, bSmooth ? GL_LINEAR : GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, bSmooth ? GL_LINEAR : GL_NEAREST); 
	glTexImage2D( GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, wid, hei, 0, GL_BGRA, GL_UNSIGNED_BYTE,pixels);

	return (int)result;
}


int oDraw_LoadImageJPG(const void* Data,int DataSize,bool bSmooth){
	int wid,hei;
	char* pixels = oDraw_DecodeJPG(Data,DataSize,&wid,&hei);
	if(!pixels)return 0;

	int result=oDraw_LoadImageBGRA(pixels,wid,hei,bSmooth);
	xfree(pixels);
	return result;
}
int oDraw_LoadImageTGA(const void* Data,int DataSize,bool bSmooth){
	int wid,hei;
	char* pixels = oDraw_DecodeTGA(Data,DataSize,&wid,&hei);
	if(!pixels)return 0;

	int result=oDraw_LoadImageBGRA(pixels,wid,hei,bSmooth);
	return result;
}

//=====================================================================================//



//============[[ STATE MODIFICATION ]]========================[[
void oDraw_EnableColor(bool bEnable){
	oDraw_Flush_BltQueue();
	glColorMask(bEnable,bEnable,bEnable,bEnable);
}
void oDraw_EnableDepthWrite(bool bEnable){
	oDraw_Flush_BltQueue();
	glDepthMask(bEnable ? GL_TRUE : GL_FALSE);
}
void oDraw_EnableDepthTest(bool bEnable){
	oDraw_Flush_BltQueue();
	if(bEnable)glEnable(GL_DEPTH_TEST);
	else glDisable(GL_DEPTH_TEST);
}
void oDraw_SetDepthFunc(bool bLower,bool bEqual){
	int func=0;
	oDraw_Flush_BltQueue();
	if(bLower && bEqual)glDepthFunc(GL_LEQUAL);
	else if(bEqual)glDepthFunc(GL_EQUAL);
	else if(bLower)glDepthFunc(GL_LESS);
}


void oSetSourceImage(int Sprite){
	static int curSprite=0;
	if(curSprite==Sprite)return;
	oDraw_Flush_BltQueue();
	curSprite=Sprite;
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB,Sprite);
}

static int blend_mode=-1;

void oDraw_SetBlendNone(){
	if(blend_mode==0)return;
	blend_mode=0;
	oDraw_Flush_BltQueue();
	glDisable(GL_BLEND);
}
void oDraw_SetBlendAlpha(){
	if(blend_mode==1)return;
	blend_mode=1;
	oDraw_Flush_BltQueue();
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}
void oDraw_SetBlendAdditive(){
	if(blend_mode==2)return;
	blend_mode=2;
	oDraw_Flush_BltQueue();
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE,GL_ONE);
}
void oDraw_SetBlendMultiply(){
	if(blend_mode==3)return;
	blend_mode=3;
	oDraw_Flush_BltQueue();
	glEnable(GL_BLEND);
	glBlendFunc(GL_ZERO,GL_SRC_COLOR);
}

//============================================================//




//===============[[ FLUSHING ]]=================================================[[
//-------------[ cached vertex data ]-----------------------------------[
struct VERTEX{
	float x,y,z;
	float u,v;
	DWORD color;
};

struct PREP_BLT{
	short left,top,right,bottom;
	short sleft,stop,sright,sbottom;
	DWORD color;
	float z;
};


#define MAX_BLTS 512
#define MAX_VERTS MAX_BLTS*6

static VERTEX  AllVerts[MAX_VERTS];
static PREP_BLT BltQueue[MAX_BLTS],*CurBltQueue;
static int NumBlits;
//----------------------------------------------------------------------/

void oDraw_Flush_BltQueue(){
	if(!NumBlits)return;

	VERTEX* v = AllVerts;
	PREP_BLT* p=BltQueue;
	int i = NumBlits;

	do{
#define PUTVTX(idx,X,Y)		v[idx].x = p->X;\
		v[idx].y = p->Y;\
		v[idx].u = p->s##X;\
		v[idx].v = p->s##Y;\
		v[idx].color = p->color;\
		v[idx].z = p->z;

		PUTVTX(0,left,top);
		PUTVTX(1,left,bottom);
		PUTVTX(2,right,bottom);
		PUTVTX(3,right,bottom);
		PUTVTX(4,right,top);
		PUTVTX(5,left,top);

		v+=6;
		p++;
	}while(--i);

	float* allvertsC = (float*)AllVerts;
	glTexCoordPointer(2,GL_FLOAT,sizeof(VERTEX),allvertsC+3);
	glColorPointer(4,GL_UNSIGNED_BYTE,sizeof(VERTEX),allvertsC+5);
	glVertexPointer(3,GL_FLOAT,sizeof(VERTEX),allvertsC);

	glDrawArrays(GL_TRIANGLES,0,NumBlits*6);

	CurBltQueue = BltQueue;
	NumBlits=0;
}
//==============================================================================//








//============================[[ BLITTING ]]===================================================================[[
void oBlt(int x,int y,int wid,int hei,int sx,int sy){
	x+= oDraw_OFFX;
	y+= oDraw_OFFY;
	CurBltQueue->left = x;
	CurBltQueue->right=x+wid;
	CurBltQueue->top=y;
	CurBltQueue->bottom=y+hei;

	CurBltQueue->sleft=sx;
	CurBltQueue->stop =sy;
	CurBltQueue->sright=sx+wid;
	CurBltQueue->sbottom=sy+hei;

	CurBltQueue->color=oDraw_COLOR;
	CurBltQueue->z = oDraw_OFFZ;

	CurBltQueue++;
	NumBlits++;
	if(NumBlits>=MAX_BLTS)oDraw_Flush_BltQueue();
}

void oBltSprite(int x,int y,const OD_SPRITE& s){
	oBlt(x,y,s.wid,s.hei,s.sx,s.sy);
}



void oBltStretch(int x,int y,int wid,int hei,int sx,int sy,int swid,int shei){
	if(wid>0 && hei>0){
		x+= oDraw_OFFX;
		y+= oDraw_OFFY;
		CurBltQueue->left = x;
		CurBltQueue->right=x+wid;
		CurBltQueue->top=y;
		CurBltQueue->bottom=y+hei;

		CurBltQueue->sleft=sx;
		CurBltQueue->stop =sy;
		CurBltQueue->sright=sx+swid;
		CurBltQueue->sbottom=sy+shei;

		CurBltQueue->color=oDraw_COLOR;
		CurBltQueue->z = oDraw_OFFZ;

		CurBltQueue++;
		NumBlits++;
		if(NumBlits>=MAX_BLTS)oDraw_Flush_BltQueue();
	}
}

void oDrawRect(int x,int y,int wid,int hei,int pixelx,int pixely){
	x+= oDraw_OFFX;
	y+= oDraw_OFFY;
	CurBltQueue->left = x;
	CurBltQueue->right=x+wid;
	CurBltQueue->top=y;
	CurBltQueue->bottom=y+hei;

	CurBltQueue->sleft=pixelx;
	CurBltQueue->stop =pixely;
	CurBltQueue->sright=pixelx;
	CurBltQueue->sbottom=pixely;

	CurBltQueue->color=oDraw_COLOR;
	CurBltQueue->z = oDraw_OFFZ;

	CurBltQueue++;
	NumBlits++;
	if(NumBlits>=MAX_BLTS)oDraw_Flush_BltQueue();
}
//=============================================================================================================//


 

//================[[ CLIPPING ]]=======================================[[
struct CLIPSTACKENTRY{
	int x,y;
	float z;
};
static CLIPSTACKENTRY clipstack[32];
static int clipstack_idx;

bool odEnterClip(int x,int y,int wid,int hei){
	return odEnterClip2(x,y,x+wid,y+hei);
}
bool odEnterClip2(int x,int y,int right,int bottom){
	CLIPSTACKENTRY* c=	&clipstack[clipstack_idx];
	c->x = oDraw_OFFX;
	c->y = oDraw_OFFY;
	c->z = oDraw_OFFZ;
	clipstack_idx++;
	clipstack_idx&=31;
	oDraw_OFFX+=x;
	oDraw_OFFY+=y;
	return true;
}
void odLeaveClip(){
	clipstack_idx--;
	clipstack_idx&=31;
	CLIPSTACKENTRY* c=	&clipstack[clipstack_idx];
	oDraw_OFFX = c->x;
	oDraw_OFFY = c->y;
	oDraw_OFFZ = c->z;
}
void odForceClip(int x,int y,int wid,int hei){
	oDraw_OFFX=x;
	oDraw_OFFY=y;
}
//=====================================================================//


//============================[[ SHADERS ]]=========================================================[[
struct SHADER{
	unsigned int vert;
	unsigned int frag;
};


static unsigned int _LoadShader(int type,const char* code){
	GLint error_pos;
	GLuint prog;
	
	
	glGenProgramsARB(1, &prog);
	glBindProgramARB(type,prog);
	glProgramStringARB(type, GL_PROGRAM_FORMAT_ASCII_ARB, (GLsizei) ustrlen(code), (GLubyte *) code);
	glGetIntegerv(GL_PROGRAM_ERROR_POSITION_ARB, &error_pos);
	if(error_pos != -1) {
		MessageBoxA(0,code,"Error loading shader",0);
		print(error_pos);
		ExitProcess(0);
	}
	return prog;
}
static SHADER LoadShader(const char* vertCode,const char* fragCode){
	SHADER s;
	s.vert = _LoadShader(GL_VERTEX_PROGRAM_ARB,vertCode);
	s.frag = _LoadShader(GL_FRAGMENT_PROGRAM_ARB,fragCode);
	return s;
}

static SHADER AllShaders[2];

static void LoadAllShaders(){
	glEnable(GL_VERTEX_PROGRAM_ARB);
	glEnable(GL_FRAGMENT_PROGRAM_ARB);



	//----------[ default shader ]------------------------------[
	/*
	void main(){
		gl_Position = ftransform();
		gl_TexCoord[0] = gl_MultiTexCoord0;
		gl_FrontColor = gl_Color;
	}
	----------------------------------------
	uniform sampler2D tex1;		// !!!! change this to RECT !!!!
	void main(){
		vec4 color = texture2D(tex1,gl_TexCoord[0].st);
		gl_FragColor = color * gl_Color;
	}
	*/

	AllShaders[0] = LoadShader(
		"!!ARBvp1.0\n"
		"PARAM c[5] = { program.local[0],state.matrix.mvp };\n"
		"MOV result.texcoord[0], vertex.texcoord[0];\n"
		"MOV result.color, vertex.color;\n"
		"DP4 result.position.w, vertex.position, c[4];\n"
		"DP4 result.position.z, vertex.position, c[3];\n"
		"DP4 result.position.y, vertex.position, c[2];\n"
		"DP4 result.position.x, vertex.position, c[1];\n"
		"END\n",

		"!!ARBfp1.0\n"
		"TEMP R0;\n"
		"TEX R0, fragment.texcoord[0], texture[0], RECT;\n"
		"MUL result.color, R0, fragment.color.primary;\n"
		"END\n"
		);
	//----------------------------------------------------------/


	//---------[ black shader ]---------------------------[
	/*
	void main(){
		gl_Position = ftransform();
		gl_FrontColor = vec4(0);
	}
	------------------------------
	void main(){
		gl_FragColor = gl_Color;
	}
	*/
	AllShaders[1] = LoadShader(
		"!!ARBvp1.0\n"
		"PARAM c[5] = { { 0 },state.matrix.mvp };\n"
		"MOV result.color, c[0].x;\n"
		"DP4 result.position.w, vertex.position, c[4];\n"
		"DP4 result.position.z, vertex.position, c[3];\n"
		"DP4 result.position.y, vertex.position, c[2];\n"
		"DP4 result.position.x, vertex.position, c[1];\n"
		"END\n",

		"!!ARBfp1.0\n"
		"MOV result.color, fragment.color.primary;\n"
		"END\n"
		);
	//----------------------------------------------------/
	


}
void oDraw_SetShader(int shaderID){
	static int curShader=-1;
	if(shaderID==curShader)return;
	oDraw_Flush_BltQueue();
	curShader=shaderID;
	glBindProgramARB(GL_VERTEX_PROGRAM_ARB,AllShaders[shaderID].vert);
	glBindProgramARB(GL_FRAGMENT_PROGRAM_ARB,AllShaders[shaderID].frag);
}


//==================================================================================================//



//===============[[ START-FRAME, END-FRAME ]]=====================================[[
void oDraw_StartDrawing(int x,int y,int wid,int hei){
	RECT r;
	GetClientRect(oDraw_HWND,&r);
	int WindowWid = r.right - r.left;
	int WindowHei = r.bottom- r.top;
	
	glViewport(0,0,WindowWid,WindowHei);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0,WindowWid,WindowHei,0,0,-501);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	oDraw_EnableColor(true);
	oDraw_EnableDepthTest(true);
	oDraw_EnableDepthWrite(true);
	oDraw_SetDepthFunc(true,true);
	oDraw_SetBlendNone();
	oDraw_SetShader(ODSHADER_DEFAULT);
	glClear(GL_DEPTH_BUFFER_BIT);

	oDraw_OFFX=0;
	oDraw_OFFY=0;
	oDraw_OFFZ=2;
	oDraw_COLOR=0xFFFFFFFF;

	clipstack_idx=0;


	CurBltQueue = BltQueue;
	NumBlits=0;
}
void oDraw_EndDrawing(int flags){
	oDraw_Flush_BltQueue();
	SwapBuffers(hDC);
}
//================================================================================//



//===========================[[ INITIALIZATION ]]============================================================================================[[
static PROC uglGetProcAddress(const char* pName,bool IsOptional){
	PROC res = wglGetProcAddress(pName);
	if(res || IsOptional)return res;
	MessageBoxA(0,pName,"Missing OpenGL extention proc!",0);
	ExitProcess(0);
	return 0;
}

static void InitGLExtentions(){
	#define OPENGL_MACRO(proc,proctype) proc = (proctype)uglGetProcAddress(#proc,false)
		OPENGL_MACRO(glProgramStringARB,PFNGLPROGRAMSTRINGARBPROC);
		OPENGL_MACRO(glGenProgramsARB,PFNGLGENPROGRAMSARBPROC); 
		OPENGL_MACRO(glBindProgramARB,PFNGLBINDPROGRAMARBPROC); 
		OPENGL_MACRO(glDeleteProgramsARB,PFNGLDELETEPROGRAMSARBPROC); 
		OPENGL_MACRO(glProgramLocalParameter4fARB,PFNGLPROGRAMLOCALPARAMETER4FARBPROC); 
		OPENGL_MACRO(glProgramLocalParameter4fvARB,PFNGLPROGRAMLOCALPARAMETER4FVARBPROC);
		OPENGL_MACRO(wglSwapIntervalEXT,PFNWGLSWAPINTERVALEXTPROC);
	#undef OPENGL_MACRO
}


bool oDraw_Init(HWND hWnd){
	oDraw_HWND = hWnd;
	static const PIXELFORMATDESCRIPTOR pfd=	{
		sizeof(PIXELFORMATDESCRIPTOR),
		1,
		PFD_DRAW_TO_WINDOW |
		PFD_GENERIC_ACCELERATED |						// Format Must Support OpenGL
		PFD_DOUBLEBUFFER,							// Must Support Double Buffering
		PFD_TYPE_RGBA,								// Request An RGBA Format
		32,										// Select Our Color Depth
		0, 0, 0, 0, 0, 0,							// Color Bits Ignored
		0,											// No Alpha Buffer
		0,											// Shift Bit Ignored
		0,											// No Accumulation Buffer
		0, 0, 0, 0,									// Accumulation Bits Ignored
		16,											// 16Bit Z-Buffer (Depth Buffer)  
		0,											// No Stencil Buffer
		0,											// No Auxiliary Buffer
		PFD_MAIN_PLANE,								// Main Drawing Layer
		0,											// Reserved
		0, 0, 0										// Layer Masks Ignored
	};

	hDC=GetDC(hWnd);
	SetPixelFormat(hDC,ChoosePixelFormat(hDC,&pfd),&pfd);
	hRC=wglCreateContext(hDC);
	wglMakeCurrent(hDC,hRC);
	

	InitGLExtentions();
	LoadAllShaders();


	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glPixelStorei(GL_UNPACK_ALIGNMENT,1);
	glEnable(GL_TEXTURE_RECTANGLE_ARB);
	//----[ set options ]---------------[
	glFrontFace(GL_CCW);
	wglSwapIntervalEXT(0);
	//----------------------------------/
	//----------[ set initial render-states ]---------------------------------[
	glDisable(GL_BLEND);	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_DEPTH_TEST); glDepthFunc(GL_LEQUAL);
	glDisable(GL_CULL_FACE);
	glDepthMask(true);
	glColorMask(true,true,true,true);
	glLineWidth(1);
	//------------------------------------------------------------------------/

	
	CurBltQueue = BltQueue;
	NumBlits=0;

	return true;
}

void oDraw_Free(){
}
//===========================================================================================================================================//
