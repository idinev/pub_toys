typedef struct{
	long	wid;
	long	hei;
	HBITMAP	hBitmap;
	long*	bits;
	long*	lastLineBits;
	long	linesize;
	long	dwFlags;
	void*	zz_pNext;
}sSprite;

typedef struct{
	long x,y,wid,hei;
	long*	lpBits;
	long 	pitch; // in DWORDs !
	long deltaX,deltaY;
	long deltaW,deltaH;
}SDLOCKEDRECT;

//------[ flags of sSprite ]------[
#define SDRAWSPRITE_HASALPHA	 1
#define SDRAWSPRITE_PREMULALPHA	 2
//--------------------------------/

//---[ sdPreprocess operations ]--------[
#define SDPREPR_ALPHA_FROM_COLOR	1
#define SDPREPR_PREMULTIPLY_ALPHA	2
//--------------------------------------/

enum{
	SD_COPY=0,
		SD_XOR,
		SD_ADD,
		SD_SUB,
		SD_OR,
		SD_AND,
		SD_SHR,
		SD_MUL,
		SD_ADDSAT,
		SD_SUBSAT,
		SD_SHRSAT,
		SD_SHLSAT
};

#define mRGB(R,G,B) (((R)<<16)|((G)<<8) | (B))

#ifdef __cplusplus
	extern "C" {
#endif

extern long SD_TransparentColor;
extern RECT SDBound; // current bounding rectangle. For experts' use
extern POINT SDDrawOffs; // current draw-offset. For experts' use


//------[ system ]----------------------------------------[
void __stdcall InitSDraw(long wid,long hei);
void __stdcall ResizeSDrawArea(long wid,long hei);
void __stdcall FreeSDraw();
//--------------------------------------------------------/


//---[ sprite operations ]--------------------------------[
void __stdcall sdDeleteSprite(sSprite* pSprite);
sSprite* __stdcall sdCreateBlankSprite(long wid,long hei);
sSprite* __stdcall sdSpriteFromHBITMAP(HBITMAP hBitmap);
sSprite* __stdcall sdSpriteFromBitmapFile(char* lpszFileName);
sSprite* __stdcall sdSpriteFromILBFile(char* lpszFileName);
sSprite* __stdcall sdSpriteFromILB(void* pSourceData);
void __stdcall sdPreprocessSprite(sSprite* pSprite,long dwOperationID,long dwColor);
//--------------------------------------------------------/


//-------[ drawing modifiers ]-----------------------------------[
bool __stdcall sdStart(HWND hWnd);
void __stdcall sdEnd();
void __stdcall sdForceUpdate();
void __stdcall sdSetSourceSprite(sSprite* pSprite);
void __stdcall sdSetTargetSprite(sSprite* pSprite);
void __stdcall sdLeaveClip();
void __stdcall sdEnterClip(long x,long y,long wid,long hei);
void __stdcall sdForceClip(long wid,long hei);
bool __stdcall sdLockRect(SDLOCKEDRECT* pLR,long x,long y,long wid,long hei);
//---------------------------------------------------------------/


//-----------[ bitmap-to-bitmap blends ]----------------------------------------------------[
void __stdcall sBlt(long x,long y,long wid,long hei,long x2,long y2);
void __stdcall sBltTrans(long x,long y,long wid,long hei,long x2,long y2);
void __stdcall sBltTransAlpha(long x,long y,long wid,long hei,long x2,long y2,long Alpha);
void __stdcall sBltTile(long TileX,long TileY,long TileWidth,long TileHeight,
			  long SpriteX,long SpriteY,long SpriteWid,long SpriteHei,
			  long StartX,long StartY);
void __stdcall sBltAlpha(long x,long y,long wid,long hei,long x2,long y2,long Alpha);
void __stdcall sBltAdd(long x,long y,long wid,long hei,long x2,long y2);
void __stdcall sBltAddFade(long x,long y,long wid,long hei,long x2,long y2,long Fader);
void __stdcall sBltTint(long x,long y,long wid,long hei,long x2,long y2,long dwColor);

void __stdcall sBltParam(long x,long y,long wid,long hei,long x2,long y2,sSprite* pSprite);
void __stdcall sBltTransParam(long x,long y,long wid,long hei,long x2,long y2,sSprite* pSprite);
void __stdcall sBltTransAlphaParam(long x,long y,long wid,long hei,long x2,long y2,long Alpha,sSprite* pSprite);
void __stdcall sBltAlphaParam(long x,long y,long wid,long hei,long x2,long y2,long Alpha,sSprite* pSprite);
void __stdcall sBltAddParam(long x,long y,long wid,long hei,long x2,long y2,sSprite* pSprite);
void __stdcall sBltAddFadeParam(long x,long y,long wid,long hei,long x2,long y2,long Fader,sSprite* pSprite);
void __stdcall sBltTintParam(long x,long y,long wid,long hei,long x2,long y2,long dwColor,sSprite* pSprite);
//------------------------------------------------------------------------------------------/

//-----------[ draw-to-bitmap blends ]--------------------------------------------------[
void __stdcall sDrawRect(long x,long y,long wid,long hei,long dwColor);
void __stdcall sDrawRectAlpha(long x,long y,long wid,long hei,long dwColor,long Alpha);
void __stdcall sDrawRectAddFade(long x,long y,long wid,long hei,long dwColor,long Alpha);
void __stdcall sDrawRectROP(long x,long y,long wid,long hei,long dwColor,long dwROP);
void __stdcall sdSetPixel(long x,long y,long dwColor);
void __stdcall sdSetPixelA(long x,long y,long dwColor,long Alpha);
long __stdcall sdGetPixel(long x,long y);
//--------------------------------------------------------------------------------------/
#ifdef __cplusplus
	}
#endif
