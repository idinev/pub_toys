

/*

xSetSourceSprite			proto pSprite:DWORD
xLoadSprite				proto lpSourceData:DWORD
xFreeSprite				proto pSprite:DWORD
xdEnterClip				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD
xdLeaveClip				proto 
xdForceClip				proto wid:DWORD,hei:DWORD


xDrawRect				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,dwColor:DWORD

xBltParamARGB_NormVsAddit		proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,pSprite:DWORD,ARGB_:DWORD,BlendMode:DWORD
xBltStretchParamARGB_NormVsAddit	proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,sw:DWORD,sh:DWORD,pSprite:DWORD,ARGB_:DWORD,BlendMode:DWORD
xBlt					proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD
xBltAlpha				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,Alpha:DWORD
xBltARGB				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,ARGB_:DWORD
xBltParam				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,pSprite:DWORD
xBltParamARGB				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,pSprite:DWORD,ARGB_:DWORD
xBltAdd					proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD
xBltAddFade				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,Alpha:DWORD
xBltAddARGB				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,ARGB_:DWORD
xBltAddParam				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,pSprite:DWORD
xBltAddParamARGB			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,pSprite:DWORD,ARGB_:DWORD
xBltStretch				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,sw:DWORD,sh:DWORD
xBltStretchAlpha			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,sw:DWORD,sh:DWORD,Alpha:DWORD
xBltStretchARGB				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,sw:DWORD,sh:DWORD,ARGB_:DWORD
xBltStretchParam			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,sw:DWORD,sh:DWORD,pSprite:DWORD
xBltStretchParamARGB			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,sw:DWORD,sh:DWORD,pSprite:DWORD,ARGB_:DWORD
xBltAddStretch				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,sw:DWORD,sh:DWORD
xBltAddStretchFade			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,sw:DWORD,sh:DWORD,Alpha:DWORD
xBltAddStretchARGB			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,sw:DWORD,sh:DWORD,ARGB_:DWORD
xBltAddStretchParam			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,sw:DWORD,sh:DWORD,pSprite:DWORD
xBltAddStretchParamARGB			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,sx:DWORD,sy:DWORD,sw:DWORD,sh:DWORD,pSprite:DWORD,ARGB_:DWORD
xdStart					proto hWnd:DWORD
xdEnd					proto 
xDraw_Init				proto dwWidth:DWORD,dwHeight:DWORD,hWnd:DWORD
xDraw_Free				proto
	
	
RGB macro R,G,B
	exitm <(((R) shl 16) or ((G) shl 8) or (B))>
	endm
	
ARGB macro A,R,G,B
	exitm <(((A) shl 24) or ((R) shl 16) or ((G) shl 8) or (B))>
endm


WM_XDRAWUPDATE	equ WM_USER+107

*/


struct OD_SPRITE{
	short sx,sy;
	short wid,hei;
};




bool oDraw_Init(HWND hWnd);
void oDraw_Free();

char* oDraw_DecodeJPG(const void* Data,int DataSize,int* Width,int* Height);
char* oDraw_DecodeTGA(const void* Data,int DataSize,int* Width,int* Height); // does not allocate data!!!
int  oDraw_LoadImage(const char* FileName,bool bSmooth=false);
int  oDraw_LoadImageBGRA(void* pixels,int wid,int hei,bool bSmooth=false);
int  oDraw_LoadImageJPG(const void* Data,int DataSize,bool bSmooth=false);
int  oDraw_LoadImageTGA(const void* Data,int DataSize,bool bSmooth=false);

void oDraw_StartDrawing(int x,int y,int wid,int hei);
void oDraw_EndDrawing(int flags);
void oDraw_Flush_BltQueue();

void oDraw_EnableColor(bool bEnable);
void oDraw_EnableDepthWrite(bool bEnable);
void oDraw_EnableDepthTest(bool bEnable);
void oDraw_SetDepthFunc(bool bLower,bool bEqual);
void oDraw_SetBlendNone();
void oDraw_SetBlendAlpha();
void oDraw_SetBlendAdditive();
void oDraw_SetBlendMultiply();
void oDraw_SetShader(int shaderID);


bool odEnterClip(int x,int y,int wid,int hei);
bool odEnterClip2(int x,int y,int right,int bottom);
void odForceClip(int x,int y,int wid,int hei);
void odLeaveClip();

void oSetSourceImage(int Sprite);

void oBlt(int x,int y,int wid,int hei,int sx,int sy);
void oBltStretch(int x,int y,int wid,int hei,int sx,int sy,int swid,int shei);
void oDrawRect(int x,int y,int wid,int hei,int pixelx,int pixely);

void oBltSprite(int x,int y,const OD_SPRITE& s);


extern int oDraw_OFFX,oDraw_OFFY;
extern float oDraw_OFFZ;
extern POINT _oDraw_LastTextureSize;



enum{
	ODSHADER_DEFAULT=0,
	ODSHADER_BLACK,
};
