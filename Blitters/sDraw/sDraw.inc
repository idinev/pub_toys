sSprite struct
	wid		dd ?
	hei		dd ?
	hBitmap		dd ?
	bits		dd ?
	;lastLineBits	dd ?
	linesize	dd ?
	dwFlags		dd ?
	zz_pNext	dd ?
sSprite ends


SDLOCKEDRECT struct
	x	dd ?
	y	dd ?
	wid	dd ?
	hei	dd ?
	lpBits	dd ?
	pitch	dd ?
	deltaX	dd ?
	deltaY 	dd ?
	deltaW	dd ?
	deltaH	dd ?
SDLOCKEDRECT ends

SDSPLINE struct
	p0 POINT <> ; starting point
	p1 POINT <> ; control-point
	p2 POINT <> ; control-point
	p3 POINT <> ; ending point
SDSPLINE ends




;------[ flags of sSprite ]------[
SDRAWSPRITE_HASALPHA	equ 1
SDRAWSPRITE_PREMULALPHA	equ 2
;--------------------------------/


;---[ sdPreprocess operations ]--------[
SDPREPR_ALPHA_FROM_COLOR	equ 1
SDPREPR_PREMULTIPLY_ALPHA	equ 2
;--------------------------------------/


;--------[ sdStartEx dwType enumeration ]----------------------------------------------------[
SDSTARTEX_ONDRAWREGION 		equ 0	; normal behaviour
SDSTARTEX_ONUPDATEREGION	equ 1	; get initial bounds from the update region
;...					; other values are interpreted as pointer to a RECT!
;--------------------------------------------------------------------------------------------/


;----------[ Raster operations (ROPs) ]--------------[
SD_COPY		equ 0
SD_XOR		equ 1
SD_ADD		equ 2
SD_SUB		equ 3
SD_OR		equ 4
SD_AND		equ 5
SD_SHR		equ 6
SD_MUL		equ 7
SD_ADDSAT	equ 8
SD_SUBSAT	equ 9
SD_SHRSAT	equ 10
SD_SHLSAT	equ 11
;-----------------------------------------------------/


;------[ read-write dwords ]------------------------[
SDVAR_ID_SD_TransparentColor	equ 0
SDVAR_ID_SD_CurFont		equ 1
SDVAR_ID_SDBackDC		equ 2 ; read-only
SDVAR_ID_SDhDC			equ 3 ; read-only
;---------------------------------------------------/

;-----[ pointers ]--------------------------------------------------[
SDVAR_ID_SDBound_ptr		equ 4 ; returns pointer to a RECT
SDVAR_ID_SDDrawOffs_ptr		equ 5 ; returns pointers to a POINT
SDVAR_ID_sTarget_Data		equ 6 ; returns pointer to sSprite
SDVAR_ID_sSource_Data		equ 7 ; returns pointer to sSprite
;-------------------------------------------------------------------/


RGB macro red,green,blue
	exitm <(red shl 16) or (green shl 8) or blue>
endm

externdef SD_TransparentColor:DWORD
externdef SD_CurFont:DWORD
externdef SDBound:RECT
externdef SDDrawOffs:POINT
externdef sTarget_Data:sSprite
externdef sSource_Data:sSprite
externdef SDBackDC:DWORD ; source-DC (DC, where sDraw draws)
externdef SDhDC:DWORD ; target-DC (DC of window)


;------[ system ]----------------------------------------[
InitSDraw			proto wid:DWORD,hei:DWORD
ResizeSDrawArea			proto wid:DWORD,hei:DWORD
FreeSDraw			proto

sdGetCtlVariable		proto VariableID:DWORD
sdSetCtlVariable		proto VariableID:DWORD,Value:DWORD ; VariableID is only SDVAR_ID_SD_TransparentColor or SDVAR_ID_SD_CurFont
;--------------------------------------------------------/

;---[ sprite operations ]--------------------------------[
sdDeleteSprite 			proto pSprite:DWORD
sdCreateBlankSprite		proto wid:DWORD,hei:DWORD
sdSpriteFromHBITMAP		proto hBitmap:DWORD
sdSpriteFromBitmapFile		proto lpszFileName:DWORD
sdSpriteFromILBFile		proto lpszFileName:DWORD
sdSpriteFromILB			proto pSourceData:DWORD
sdSpriteFromJPG			proto pData:DWORD,DataSize:DWORD
sdSpriteFromJPGFile		proto lpszFileName:DWORD

sdPreprocessSprite		proto pSprite:DWORD,dwOperationID:DWORD,dwColor:DWORD
;--------------------------------------------------------/

;-------[ drawing modifiers ]-----------------------------------[
sdStart				proto hWnd:DWORD
sdStartEx			proto hWnd:DWORD,dwType:DWORD
sdEnd				proto
sdEndEx				proto bDoUpdate:DWORD
sdFetchBackground	proto
sdForceUpdate			proto
sdSetSourceSprite		proto pSprite:DWORD
sdSetTargetSprite		proto pSprite:DWORD
sdLeaveClip			proto
sdEnterClip			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD
sdForceClip			proto wid:DWORD,hei:DWORD

sdLockRect			proto pLR:DWORD,x:DWORD,y:DWORD,wid:DWORD,hei:DWORD


sdStartDrawingOnSprite		proto pTargetSprite:DWORD
sdEndDrawingOnSprite		proto
;---------------------------------------------------------------/




;-----------[ bitmap-to-bitmap blends ]----------------------------------------------------[
sBlt				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD
sBltTrans			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD
sBltTile 			proto TileX:DWORD,TileY:DWORD,TileWidth:DWORD,TileHeight:DWORD,\
				      SpriteX:DWORD,SpriteY:DWORD,SpriteWid:DWORD,SpriteHei:DWORD,StartX:DWORD,StartY:DWORD
sBltAlpha			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,Alpha:DWORD
sBltTransAlpha			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,Alpha:DWORD
sBltAdd				proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD
sBltAddFade			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,Fader:DWORD
sBltTint			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,dwColor:DWORD
sBltTintDirect			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,dwBackColor:DWORD,dwColor:DWORD

sBltParam			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,pSprite:DWORD
sBltTransParam			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,pSprite:DWORD
sBltAlphaParam			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,Alpha:DWORD,pSprite:DWORD
sBltTransAlphaParam		proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,Alpha:DWORD,pSprite:DWORD
sBltAddParam			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,pSprite:DWORD
sBltAddFadeParam		proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,Fader:DWORD,pSprite:DWORD
sBltTintParam			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,x2:DWORD,y2:DWORD,dwColor:DWORD,pSprite:DWORD
;------------------------------------------------------------------------------------------/

;-----------[ draw-to-bitmap blends ]--------------------------------------------------[
sDrawRect			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,dwColor:DWORD
sDrawRectAlpha			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,dwColor:DWORD,Alpha	:DWORD
sDrawRectAddFade		proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,dwColor:DWORD,Alpha:DWORD
sDrawRectROP			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,dwColor:DWORD,dwROP:DWORD
sdGetPixel			proto x:DWORD,y:DWORD
sdSetPixel			proto x:DWORD,y:DWORD,dwColor:DWORD
sdSetPixelA			proto x:DWORD,y:DWORD,dwColor:DWORD,Alpha:DWORD

sDrawLine			proto x:DWORD,y:DWORD,x2:DWORD,y2:DWORD,dwColor:DWORD ; anti-aliased line
sDrawFastLine			proto x:DWORD,y:DWORD,x2:DWORD,y2:DWORD,dwColor:DWORD ; simple line, using Bresenham's algo
sDrawLineCustom			proto x:DWORD,y:DWORD,x2:DWORD,y2:DWORD,pfCallback:DWORD,dwWidth:DWORD,dwColor:DWORD
sDrawLineH			proto x:DWORD,y:DWORD,wid:DWORD,dwColor:DWORD
sDrawLineV			proto x:DWORD,y:DWORD,hei:DWORD,dwColor:DWORD
sDrawLineH_HalfAlpha		proto x:DWORD,y:DWORD,wid:DWORD,dwColor:DWORD
sDrawLineV_HalfAlpha		proto x:DWORD,y:DWORD,hei:DWORD,dwColor:DWORD
sDrawLineHAdd			proto x:DWORD,y:DWORD,wid:DWORD,dwColor:DWORD
sDrawLineVAdd			proto x:DWORD,y:DWORD,hei:DWORD,dwColor:DWORD

sDrawBSpline			proto pSpline:ptr SDSPLINE,numPoints:DWORD,dwColor:DWORD ; 4-point B-Spline
sDrawBSplineShade		proto pSpline:ptr SDSPLINE,numPoints:DWORD,dwColor:DWORD,pShadeFunc:DWORD,ShadeWid:DWORD

sDrawRectFrame			proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,dwColor:DWORD
sDrawRectFrame3D 		proto x:DWORD,y:DWORD,wid:DWORD,hei:DWORD,dwColor:DWORD,dwLightColor:DWORD,dwDarkColor:DWORD
;--------------------------------------------------------------------------------------/


;---------[ text drawing ]-------------------------------------------------------------[
sdLoadFont			proto pFontData:DWORD
sTextOUTGetDrawnSize		proto pText:DWORD
sTextOut			proto x:DWORD,y:DWORD,pText:DWORD,dwColor:DWORD
sdPrintDec			proto x:DWORD,y:DWORD,nValue:DWORD,dwColor:DWORD
;--------------------------------------------------------------------------------------/

