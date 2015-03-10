USE_BANK 	= 0
COMPILE_AS_DLL	= 0
COMPILE_AS_EXE  = 0
INCLUDE_COPYRIGHT_TEXT = 1
ALLOW_EXTERNAL_LIBS = 1



if USE_BANK
	include \masm32\ultrano\bank\base.inc
	HEAP2 textequ <HEAP1>
else
	include src\CompatLayer.inc	
endif

include ../sDraw.inc

if ALLOW_EXTERNAL_LIBS
includelib \masm32\lib\ole32.lib
includelib \masm32\lib\olepro32.lib
endif


option PROC:PRIVATE

public SD_TransparentColor
public SD_CurFont
public sTarget_Data
public sSource_Data
	

SRECT STRUCT
  left    SDWORD ?
  top     SDWORD ?
  right   SDWORD ?
  bottom  SDWORD ?
SRECT ENDS

SBLTPARAM struct
	x dd ?
	y dd ?
	wid dd ?
	hei dd ?
	x2 dd ?
	y2 dd ?
SBLTPARAM ends


backDC textequ <SDBackDC>
public backDC
public SDhDC

.data
	SD_TransparentColor	dd 0FF00FFh
	SD_CurFont 		dd 0
.data?
	align 16
	SDBound 	SRECT <>	
	SDOriginalBound	SRECT <>
	
	SDDrawOffs	POINT <>
	ScreenSize	POINT <>
	
	SDhWnd		dd ?
	SDhDC		dd ?
	
	backDC		dd ?
	backDC_PrevHBmp	dd ?
	
	SD_BackSprite	dd ?
	
	
	align 16
	sTarget_Data	sSprite <>
	sSource_Data	sSprite <>
	
	pTargetSprite	dd ?
	pSourceSprite	dd ?
.code
	






		
.data
	sd_pLastSprite dd 0
.code
	

sdRegisterSprite proc PRIVATE uses eax edx pSprite
	mov edx,pSprite
	.if edx
		
		mov eax,sd_pLastSprite
		mov sd_pLastSprite,edx
		mov [edx].sSprite.zz_pNext,eax
	.endif
	ret
sdRegisterSprite endp

sdUnregisterSprite proc PRIVATE uses eax ecx edx pSprite
	mov edx,pSprite
	mov ecx,sd_pLastSprite
	test edx,edx
	jz _ret
	
	.if edx==ecx
		mov eax,[ecx].sSprite.zz_pNext
		mov sd_pLastSprite,eax
		jmp _ret
	.endif
	
	.while ecx
		mov eax,[ecx].sSprite.zz_pNext
		.if eax==edx ; found it
			mov eax,[edx].sSprite.zz_pNext
			mov [ecx].sSprite.zz_pNext,eax
			jmp _ret
		.endif
		mov ecx,eax		
	.endw
	
_ret:	ret
sdUnregisterSprite endp

sdDeleteSprite proc PUBLIC UseAll pSprite
	mov ecx,pSprite
	test ecx,ecx
	jz _ret
	invoke sdUnregisterSprite,ecx
	
	free [ecx].sSprite.bits
	free ecx
	
_ret:	ret
sdDeleteSprite endp

sdDeleteAllSprites proc PRIVATE UseAll
	.while sd_pLastSprite
		invoke sdDeleteSprite,sd_pLastSprite
	.endw
	
	ret
sdDeleteAllSprites endp

	


CreateDIBsprite proc PRIVATE UseMost wid,hei
	local hdr1:BITMAPINFOHEADER
	local s:sSprite
	
	m2m s.wid,wid
	m2m s.hei,hei
	mov s.dwFlags,0
	
	
	;--------[ setup bitmapinfohdr ]-----------[
	Clear hdr1
	mov hdr1.biSize,sizeof BITMAPINFOHEADER
	m2m hdr1.biWidth,wid
	m2m hdr1.biHeight,hei
	neg hdr1.biHeight  ; !!!!!! make the height negative
	mov hdr1.biPlanes,1
	mov hdr1.biBitCount,32
	mov hdr1.biCompression,BI_RGB
	mov eax,wid
	mul hei
	shl eax,2
	mov hdr1.biSizeImage,eax
	mov hdr1.biClrImportant,0
	mov hdr1.biClrUsed,0
	;-------------------------------------------/
	
	invoke CreateDIBSection,backDC,addr hdr1,DIB_RGB_COLORS,addr s.bits,0,0
	mov s.hBitmap,eax
	
	;---[ compute stuff ]-------[
	mov eax,wid
	shl eax,2
	mov s.linesize,eax
	;---------------------------/
	
	invoke memclone,addr s,sizeof sSprite
	ret
CreateDIBsprite endp


sdSpriteFromHBITMAP proc PUBLIC UseMost hBitmap
	local bi:BITMAP,wid,hei
	local hdr1:BITMAPINFOHEADER
	local s:sSprite
	
	.if !hBitmap
		xor eax,eax
		ret
	.endif
	
	
	invoke GetObject,hBitmap,sizeof BITMAP,addr bi
	m2m wid,bi.bmWidth
	m2m hei,bi.bmHeight
		
	
	
	m2m s.wid,wid
	m2m s.hei,hei
	mov s.dwFlags,0
	mov s.hBitmap,0
	
	;--------[ setup bitmapinfohdr ]-----------[
	Clear hdr1
	mov hdr1.biSize,sizeof BITMAPINFOHEADER
	m2m hdr1.biWidth,wid
	m2m hdr1.biHeight,hei
	neg hdr1.biHeight
	mov hdr1.biPlanes,1
	mov hdr1.biBitCount,32
	mov hdr1.biCompression,BI_RGB
	mov eax,wid
	mul hei
	shl eax,2
	mov hdr1.biSizeImage,eax
	;-------------------------------------------/
	
	
	mov s.bits,malloc(hdr1.biSizeImage)
	invoke GetDIBits,backDC,hBitmap,0,hei,s.bits,addr hdr1,DIB_RGB_COLORS
	
	
	;---[ compute stuff ]-------[
	mov eax,wid
	shl eax,2
	mov s.linesize,eax
	;---------------------------/
	
	invoke memclone,addr s,sizeof sSprite
	invoke sdRegisterSprite,eax
	
	ret
sdSpriteFromHBITMAP endp


sdCreateBlankSprite proc PUBLIC UseMost wid,hei
	local s:sSprite
	
	m2m s.wid,wid
	m2m s.hei,hei
	mov s.dwFlags,0
	mov s.hBitmap,0
	
	mov eax,wid
	imul eax,hei
	shl eax,2
	mov s.bits,malloc(eax)
	
	;---[ compute stuff ]-------[
	mov eax,wid
	shl eax,2
	mov s.linesize,eax
	;---------------------------/
	
	invoke memclone,addr s,sizeof sSprite
	invoke sdRegisterSprite,eax
	
	ret
sdCreateBlankSprite endp


sdSpriteFromBitmapFile proc PUBLIC UseMost lpszFileName
	invoke LoadImage,0,lpszFileName,IMAGE_BITMAP,0,0,LR_LOADFROMFILE
	.if eax
		mov ecx,eax
		invoke sdSpriteFromHBITMAP,eax
		push eax
		invoke DeleteObject,ecx
		pop eax
	.endif
	ret
sdSpriteFromBitmapFile endp



sdSpriteFromILB proc PUBLIC UseMost lpSourceData
	local wid,hei,IsAlpha,WIDxHEI
	local PackedSize,pPackedBuf,pUnpackedBuf
	local pSprite,wid2
	
	;-----[ get info from the ILIX Bitmap ]----[
	mov IsAlpha,0
	mov ebx,lpSourceData
	mov eax,[ebx]
	.if eax & 65536
		mov IsAlpha,1
		movzx eax,ax
	.endif
	mov wid,eax
	mov eax,[ebx+4]
	mov hei,eax
	mov eax,[ebx+8]
	mov PackedSize,eax
	add ebx,12
	mov pPackedBuf,ebx
	
	mov eax,wid
	imul eax,hei
	mov WIDxHEI,eax
	.if IsAlpha
		lea eax,[eax+eax*2]
	.else
		shl eax,1
	.endif
	mov pUnpackedBuf,malloc(eax)
	;------------------------------------------/
	
	;--------[ decompress into 16-bit or 16+8-bit ]----[
	invoke unpack,pPackedBuf,pUnpackedBuf,PackedSize
	;--------------------------------------------------/
	
	invoke sdCreateBlankSprite,wid,hei
	mov pSprite,eax
	
	mov edi,[eax].sSprite.bits
	mov esi,pUnpackedBuf
	
	;------------[ deflate 16->32 ]-----------------------------------------------------------[
	.if IsAlpha
		mov eax,pSprite
		mov [eax].sSprite.dwFlags,SDRAWSPRITE_HASALPHA
		mov ecx,WIDxHEI
		lea ecx,[esi+ecx*2]
		nextline:
			m2m wid2,wid
			align 16
			@@:
				;---[16->32]--------\
				mov dx,[esi]
				mov al,dl
				shl al,3
				mov [edi+0],al
				shr dx,5
				mov al,dl
				shl al,2
				mov [edi+1],al
				mov al,[ecx]
				shr dx,6
				shl dl,3
				mov [edi+2],dl
				mov byte ptr[edi+3],al
				;-------------------/
				add esi,2
				add edi,4
				inc ecx
			dec wid2
			jnz @B
			
		dec hei
		jnz nextline
		
	.else
		nextline2:
			mov ecx,wid
			align 16
			@@:
				;---[16->24]--------\
				mov dx,[esi]
				mov al,dl
				shl al,3
				mov [edi+0],al
				shr dx,5
				mov al,dl
				shl al,2
				mov [edi+1],al
				shr dx,6
				shl dl,3
				mov [edi+2],dl
				mov byte ptr[edi+3],255
				;-------------------/
				add esi,2
				add edi,4
			dec ecx
			jnz @B
			
		dec hei
		jnz nextline2
			
	.endif
	;-----------------------------------------------------------------------------------------/
	
	mov eax,pSprite
	ret
sdSpriteFromILB endp

sdSpriteFromILBFile proc PUBLIC UseMost lpszFileName
	local nread,f1,fsiz,pPacked
	
	invoke CreateFile,lpszFileName,GENERIC_READ,0,0,OPEN_EXISTING,0,0
	.if eax==-1
		xor eax,eax
		ret
	.endif
	mov f1,eax
	invoke GetFileSize,f1,0
	mov fsiz,eax
	mov pPacked,malloc(eax)
	invoke ReadFile,f1,pPacked,fsiz,addr nread,0
	invoke CloseHandle,f1
	invoke sdSpriteFromILB,pPacked
	free pPacked
	ret
sdSpriteFromILBFile endp



.data
	IID_IPicture dd 07BF80980H
		dw 0BF32H, 0101AH
		db 08BH, 0BBH, 000H, 0AAH, 000H, 030H, 00CH, 0ABH
.code
	
	

sdSpriteFromJPG proc PUBLIC UseMost pData,DataSize
	local PictuBaka,pstm,hGlobal
	local hBmp
	local pSprite
	
	mov pSprite,0
	
	;-----[ make hGlobal ]----------------------[
	invoke GlobalAlloc,GMEM_MOVEABLE,DataSize
	mov hGlobal, eax
	test eax,eax
	jz _ret
	invoke GlobalLock, hGlobal
	test eax,eax
	je _ret ; we had an error
	
	invoke memmove,eax,pData,DataSize
	invoke GlobalUnlock, hGlobal
	;-------------------------------------------/
	
	;----[ create IStream* from global memory ]------------[
	CreateStreamOnHGlobal proto :DWORD,:DWORD,:DWORD
	OleLoadPicture proto :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
	CoInitialize proto :DWORD
	CoUninitialize proto
	
	invoke CreateStreamOnHGlobal, hGlobal,1,addr pstm
	test eax,eax
	jnz _ret
	;------------------------------------------------------/
	
	
	;-----[ Create IPicture from image file ]---------------------------------------[
	mov ecx, PictuBaka
        invoke OleLoadPicture, pstm, DataSize,0, ADDR IID_IPicture, addr PictuBaka
	.if eax
		; pstm->Release()
		multi  mov eax,pstm | push eax | mov eax,[eax] | call dword ptr[eax+2*4]
		
		jmp _ret
	.endif
	;-------------------------------------------------------------------------------/
	
	
	;---------[ make the pSprite ]--------------------------------------------------------------------------[
	; PictuBaka->get_Handle(&hBmp)
	multi  lea eax,hBmp | push eax | mov eax,PictuBaka | push eax | mov eax,[eax] | call dword ptr[eax+3*4]
	.if !eax
		invoke sdSpriteFromHBITMAP,hBmp
		mov pSprite,eax
	.endif
	;-------------------------------------------------------------------------------------------------------/
	
	;--------[ release stuff ]----------------------------------------------------[
	; PictuBaka->Release()
	multi  mov eax,PictuBaka | push eax | mov eax,[eax] | call dword ptr[eax+2*4]
	
	; pstm->Release()
	multi  mov eax,pstm | push eax | mov eax,[eax] | call dword ptr[eax+2*4]
	;-----------------------------------------------------------------------------/
	
_ret:	
	.if hGlobal
		invoke GlobalFree,hGlobal
	.endif
	mov eax,pSprite
	ret
sdSpriteFromJPG endp


sdSpriteFromJPGFile proc PUBLIC UseMost lpszFileName
	local nread,f1,fsiz,pPacked
	
	invoke CreateFile,lpszFileName,GENERIC_READ,0,0,OPEN_EXISTING,0,0
	.if eax==-1
		xor eax,eax
		ret
	.endif
	mov f1,eax
	invoke GetFileSize,f1,0
	mov fsiz,eax
	mov pPacked,malloc(eax)
	invoke ReadFile,f1,pPacked,fsiz,addr nread,0
	invoke CloseHandle,f1
	invoke sdSpriteFromJPG,pPacked,fsiz
	free pPacked
	ret
sdSpriteFromJPGFile endp



sdSetSourceSprite proc PUBLIC uses ecx esi edi pSprite
	mov esi,pSprite
	.if !esi
		mov esi,SD_BackSprite
	.endif
	mov pSourceSprite,esi
	mov edi,offset sSource_Data
	mov ecx,(sizeof sSprite)/4
	rep movsd
	ret
sdSetSourceSprite endp

sdSetTargetSprite proc PUBLIC uses eax pSprite
	mov eax,pSprite
	.if !eax
		mov eax,SD_BackSprite
	.endif
	mov pTargetSprite,eax
	
	invoke memmove,addr sTarget_Data,eax,sizeof sSprite
	ret
sdSetTargetSprite endp












sdSpritePreprocess_AlphaFromColor proc PRIVATE UseAll pSprite,dwColor
	local dwSize
	local iR,iG,iB,aA
	
	
	
	;-----[ compute iR,iG,iB ]-----[
	mov eax,dwColor
	movzx edx,al
	mov iB,edx
	movzx edx,ah
	mov iG,edx
	shr eax,16
	movzx edx,al
	mov iR,edx
	;------------------------------/
	
	
	
	
	mov ecx,pSprite
	test ecx,ecx
	jz _ret
	mov eax,[ecx].sSprite.wid
	imul eax,[ecx].sSprite.hei
	mov dwSize,eax
	mov edi,[ecx].sSprite.bits
	or [ecx].sSprite.dwFlags,SDRAWSPRITE_HASALPHA
	
	align 16
	nextpix:
	mov eax,[edi]
	mov ebx,eax
	;--------[ process pixel ]----------------[
	
	;---[ fetch sR,sG,sB ]--[
	movzx ecx,al
	sub ecx,iB
	jge @F
		neg ecx
	@@:	
	movzx edx,ah
	sub edx,iG
	jge @F
		neg edx
	@@:
	.if ecx<edx
		mov ecx,edx
	.endif
	shr eax,16
	movzx edx,al
	sub edx,iR
	jge @F
		neg edx
	@@:
	.if ecx<edx
		mov ecx,edx
	.endif
	; ecx = max alpha
	;-----------------------/
	
		
	
	
	
	;------[ compose and put sR,sG,sB,aA ]-------[
	and ebx,0FFFFFFh
	shl ecx,24
	or ebx,ecx
	mov [edi],ebx
	;-----------------------------------------/
	add edi,4
	dec dwSize
	jnz nextpix
	
	
_ret:	ret
sdSpritePreprocess_AlphaFromColor endp

sdSpritePreprocess_PremultiplyAlpha proc PRIVATE UseAll pSprite
	local dwSize
	
	mov ecx,pSprite
	test ecx,ecx
	jz _ret
	mov eax,[ecx].sSprite.wid
	imul eax,[ecx].sSprite.hei
	mov dwSize,eax
	mov edi,[ecx].sSprite.bits
	or [ecx].sSprite.dwFlags,SDRAWSPRITE_PREMULALPHA
	
	align 16
	@@:
	mov eax,[edi]
	mov ecx,eax
	mov ebx,eax
	shr ecx,24
	and eax,0FF00FFh
	and ebx,000FF00h
	imul eax,ecx
	imul ebx,ecx
	and eax,0FF00FF00h
	and ebx,000FF0000h
	shl ecx,24
	or eax,ebx
	shr eax,8
	or eax,ecx
	mov [edi],eax
	add edi,4
	dec dwSize
	jnz @B
	
_ret:	ret
sdSpritePreprocess_PremultiplyAlpha endp



sdPreprocessSprite proc PUBLIC pSprite,dwOperationID,dwColor
	.if dwOperationID==SDPREPR_ALPHA_FROM_COLOR
		invoke sdSpritePreprocess_AlphaFromColor,pSprite,dwColor
	.elseif dwOperationID==SDPREPR_PREMULTIPLY_ALPHA
		invoke sdSpritePreprocess_PremultiplyAlpha,pSprite
	.endif
		
	ret
sdPreprocessSprite endp


;=====[[ some_Macros >>===\
MAKERECT macro Rect1,x,y,wid,hei
	mov eax,x
	mov Rect1.left,eax
	add eax,wid
	mov Rect1.right,eax
	mov eax,y
	mov Rect1.top,eax
	add eax,hei
	mov Rect1.bottom,eax
endm

CHECKDRAWRECT macro
	
	mov eax,x
	mov ebx,y
	mov ecx,wid
	mov edx,hei
	add eax,SDDrawOffs.x
	add ebx,SDDrawOffs.y
	add ecx,eax
	add edx,ebx
	
	cmp eax,SDBound.left
	jge @F
		mov eax,SDBound.left
	@@:
	cmp ebx,SDBound.top
	jge @F
		mov ebx,SDBound.top
	@@:
	
	cmp ecx,SDBound.right
	jle @F
		mov ecx,SDBound.right
	@@:
	
	cmp edx,SDBound.bottom
	jle @F
		mov edx,SDBound.bottom
	@@:
	
	sub ecx,eax
	jle _ret
	sub edx,ebx
	jle _ret
	mov x,eax
	mov y,ebx
	mov wid,ecx
	mov hei,edx
endm

CLIPRECTADJUST macro Rect,ClipRect,ptX,ptY
	;----[ clip left,top ]---------[
	mov eax,ClipRect.left
	sub eax,Rect.left
	jle @F
		add Rect.left,eax
		add ptX,eax
	@@:
	
	mov eax,ClipRect.top
	sub eax,Rect.top
	jle @F
		add Rect.top,eax
		add ptY,eax
	@@:
	;---------------------------------/
	
	;-----[ clip right,bottom ]----------[
	mov eax,ClipRect.right
	cmp eax,Rect.right
	jge @F
		mov Rect.right,eax
	@@:
	mov eax,ClipRect.bottom
	cmp eax,Rect.bottom
	jge @F
		mov Rect.bottom,eax
	@@:
	;------------------------------------/
endm

COMPUTEBLTBITS macro
	;---[ compute pBits ]--------------[
	mov eax,y
	mov edi,x
	shl edi,2
	imul eax,sTarget_Data.linesize
	add edi,eax
	add edi,sTarget_Data.bits
	;----------------------------------/
	;-[ compute extraDest ]---[
	mov eax,sTarget_Data.wid
	sub eax,wid
	shl eax,2
	mov extraDest,eax
	;-------------------------/
endm

COMPUTEBLTBITS1 macro
	;---[ compute pBits ]--------------[
	mov eax,y
	mov edi,x
	shl edi,2
	imul eax,sTarget_Data.linesize
	add edi,eax
	add edi,sTarget_Data.bits
	;----------------------------------/
endm

COMPUTEBLTBITS2 macro
	;---[ compute pBits ]--------------[
	mov eax,y
	mov edi,x
	shl edi,2
	imul eax,sTarget_Data.linesize
	add edi,eax
	add edi,sTarget_Data.bits
	;----------------------------------/
	
	;---[ compute pBits2 ]--------------[
	mov eax,y2
	mov esi,x2
	shl esi,2
	imul eax,sSource_Data.linesize
	add esi,eax
	add esi,sSource_Data.bits
	;-----------------------------------/
	
	;--[ compute extraDest,extraSrc ]--[
	mov eax,sTarget_Data.wid
	sub eax,wid
	shl eax,2
	mov extraDest,eax
	mov eax,sSource_Data.wid
	sub eax,wid
	shl eax,2
	mov extraSrc,eax
	;----------------------------------/
	
endm

COMPUTEBLTBITS3 macro
	;---[ compute pBits ]--------------[
	mov eax,y
	mov edi,x
	shl edi,2
	imul eax,sTarget_Data.linesize
	add edi,eax
	add edi,sTarget_Data.bits
	;----------------------------------/
	
	;---[ compute pBits2 ]--------------[
	mov eax,y2
	mov esi,x2
	shl esi,2
	imul eax,sSource_Data.linesize
	add esi,eax
	add esi,sSource_Data.bits
	;-----------------------------------/
endm



;=======/
;=====<< RectTools >>===\
MakeRect proc uses eax ecx pOutRect,x,y,wid,hei
	mov ecx,pOutRect
	MAKERECT [ecx].RECT,x,y,wid,hei
	ret
MakeRect endp

;=======/
;=====<< FixupSBLTparams >>===\
;
; Called in sdBlt,sdBltTrans,sdBltAlpha, and the like
; Fixes-up the "x,y,wid,hei,x2,y2" params right into 
; the stack, ZeroFlag is set if we needn't draw
;

FixupSBLTparams proc pX
	local Dest:SRECT,BRec:SRECT
	assume ecx:ptr SBLTPARAM
	
	mov ecx,pX
	mov eax,SDDrawOffs.x
	add [ecx].x,eax
	mov eax,SDDrawOffs.y
	add [ecx].y,eax
	
	MAKERECT Dest,[ecx].x,[ecx].y,[ecx].wid,[ecx].hei
	CLIPRECTADJUST Dest,SDBound,[ecx].x2,[ecx].y2
	
	mov eax,Dest.right
	sub eax,Dest.left
	jle _ret
	mov [ecx].wid,eax
	
	mov eax,Dest.bottom
	sub eax,Dest.top
	jle _ret
	mov [ecx].hei,eax
	
	mov eax,Dest.left
	mov [ecx].x,eax
	mov eax,Dest.top
	mov [ecx].y,eax
	
	
	assume ecx:nothing
_done:	
	xor eax,eax
	inc eax
	ret
	
_ret:	; failed
	xor eax,eax
	ret	
FixupSBLTparams endp	
;=======/


;=====[[ sdEnter/Leave/ForceClip >>===\
.data?
	pClipStack	dd ?
	ClipStackData	db 24*40 dup (?)
	
.code	
	; clipper size = 24 bytes
	

sdLeaveClip proc PUBLIC uses eax
	sub pClipStack,24
	mov eax,pClipStack
	
	push dword ptr[eax+ 0]
	push dword ptr[eax+ 4]
	push dword ptr[eax+ 8]
	push dword ptr[eax+12]
	push dword ptr[eax+16]
	push dword ptr[eax+20]
	
	pop SDBound.left
	pop SDBound.top
	pop SDBound.right
	pop SDBound.bottom
	pop SDDrawOffs.x
	pop SDDrawOffs.y
	
	ret
sdLeaveClip endp

sdEnterClip proc PUBLIC uses eax ebx ecx edx x,y,wid,hei
		
	;-----[ push clipper ]---------------[
	mov eax,pClipStack
	push SDBound.left
	push SDBound.top
	push SDBound.right
	push SDBound.bottom
	push SDDrawOffs.x
	push SDDrawOffs.y
	
	pop dword ptr[eax+ 0]
	pop dword ptr[eax+ 4]
	pop dword ptr[eax+ 8]
	pop dword ptr[eax+12]
	pop dword ptr[eax+16]
	pop dword ptr[eax+20]
	
	add pClipStack,24
	;------------------------------------/
		
	mov eax,x
	mov ebx,y
	mov ecx,wid
	mov edx,hei
	add eax,SDDrawOffs.x
	add ebx,SDDrawOffs.y
	mov SDDrawOffs.x,eax
	mov SDDrawOffs.y,ebx
	add ecx,eax
	add edx,ebx
	
	
	;------[ intersect rectangle ]----------[
	cmp eax,SDBound.left
	jge @F
		mov eax,SDBound.left
	@@:
	cmp ebx,SDBound.top
	jge @F
		mov ebx,SDBound.top
	@@:
	
	cmp ecx,SDBound.right
	jle @F
		mov ecx,SDBound.right
	@@:
	
	cmp edx,SDBound.bottom
	jle @F
		mov edx,SDBound.bottom
	@@:
	;---------------------------------------/
	
	;----[ check if left>right ]----[
	cmp eax,ecx
	jle @F
		mov ecx,eax
	@@:
	;-------------------------------/
	;---[ check if top>bottom ]----[
	cmp ebx,edx
	jle @F
		mov edx,ebx
	@@:
	;------------------------------/
	
	
	mov SDBound.left,eax
	mov SDBound.top,ebx
	mov SDBound.right,ecx
	mov SDBound.bottom,edx
	
	;------[ set zero-flag if clip is null ]-----[
	.if eax!=ecx && ebx!=edx
		xor eax,eax
		inc eax	
	.else
		xor eax,eax
	.endif
	;--------------------------------------------/
	
	ret
sdEnterClip endp

sdForceClip proc PUBLIC uses eax ebx wid,hei
	xor eax,eax
	mov SDDrawOffs.x,eax
	mov SDDrawOffs.y,eax
	mov SDBound.left,eax
	mov SDBound.top,eax
	
	mov eax,wid
	mov ebx,hei
	.if eax>sTarget_Data.wid
		mov eax,sTarget_Data.wid
	.endif
	.if ebx>sTarget_Data.hei
		mov ebx,sTarget_Data.hei
	.endif
	
	mov SDBound.right,eax
	mov SDBound.bottom,ebx
	ret
sdForceClip endp
;=======/


;=====[[ sdLockRect >>===\
sdLockRect proc PUBLIC UseMost pLR,x,y,wid,hei
	local WasClipped
	
	mov esi,pLR
	
	;-----[ compute rectangle ]-----[
	mov WasClipped,0
	mov eax,x
	mov ebx,y
	mov ecx,wid
	mov edx,hei
	add eax,SDDrawOffs.x
	add ebx,SDDrawOffs.y
	add ecx,eax
	add edx,ebx
	;-------------------------------/
	
	;------[ clip to SDBound ]----------[
	cmp eax,SDBound.left
	jge @F
		mov eax,SDBound.left
		mov WasClipped,1
	@@:
	cmp ebx,SDBound.top
	jge @F
		mov ebx,SDBound.top
		mov WasClipped,1
	@@:
	cmp ecx,SDBound.right
	jle @F
		mov ecx,SDBound.right
		mov WasClipped,1
	@@:
	cmp edx,SDBound.bottom
	jle @F
		mov edx,SDBound.bottom
		mov WasClipped,1
	@@:
	
	sub ecx,eax
	jle _ret
	sub edx,ebx
	jle _ret
	;------------------------------------/
	
	
	;---[ compute pBits ]--------------[
	mov edi,eax
	push ebx
	shl edi,2
	imul ebx,sTarget_Data.linesize
	add edi,sTarget_Data.bits
	add edi,ebx
	pop ebx
	;----------------------------------/
	
	
	
	sub eax,SDDrawOffs.x
	sub ebx,SDDrawOffs.y
	
	
	mov [esi].SDLOCKEDRECT.x,eax
	mov [esi].SDLOCKEDRECT.y,ebx
	mov [esi].SDLOCKEDRECT.wid,ecx
	mov [esi].SDLOCKEDRECT.hei,edx
	mov [esi].SDLOCKEDRECT.lpBits,edi
	sub eax,x
	sub ebx,y
	sub ecx,wid
	sub edx,hei
	neg ecx
	neg edx
	mov [esi].SDLOCKEDRECT.deltaX,eax
	mov [esi].SDLOCKEDRECT.deltaY,ebx
	mov [esi].SDLOCKEDRECT.deltaW,ecx
	mov [esi].SDLOCKEDRECT.deltaH,edx
	
	
	mov eax,sTarget_Data.wid
	mov [esi].SDLOCKEDRECT.pitch,eax
	
	mov eax,WasClipped
	inc eax
	ret	
_ret:
	xor eax,eax
	ret
sdLockRect endp
;=======/


;=====[[ copyright >>===\
if INCLUDE_COPYRIGHT_TEXT

db 13,10,13,10,13,10
db "======================================================================",13,10
db "======================================================================",13,10
db "*      sDraw Library:  COPYRIGHT   Ultrano Software,                 *",13,10
db "*                              Ilian Dinev                           *",13,10
db "*                       http://www.ultranos.com                      *",13,10
db "======================================================================",13,10
db "======================================================================",13,10
db 13,10,13,10,13,10

endif
;=======/


;=====[[ sDrawRect/RectFrame/RectFrame3D >>===\
sDrawLineH proc PUBLIC UseAll x,y,wid,dwColor
	mov ecx,x
	mov edi,y
	mov eax,wid
	add ecx,SDDrawOffs.x
	add edi,SDDrawOffs.y
	add eax,ecx
	cmp edi,SDBound.top
	jl _ret	
	cmp edi,SDBound.bottom
	jge _ret
	
	cmp ecx,SDBound.left
	jge @F
		mov ecx,SDBound.left
	@@:
	cmp eax,SDBound.right
	jle @F
		mov eax,SDBound.right
	@@:
	sub eax,ecx
	jle _ret
	imul edi,sTarget_Data.linesize
	shl ecx,2
	add edi,sTarget_Data.bits
	add edi,ecx
	mov ecx,eax
	mov eax,dwColor
	
	rep stosd
	
	
_ret:	ret
sDrawLineH endp


sDrawLineV proc PUBLIC UseAll x,y,hei,dwColor
	mov ecx,x
	mov edi,y
	mov eax,hei
	add ecx,SDDrawOffs.x
	add edi,SDDrawOffs.y
	add eax,edi
	
	cmp ecx,SDBound.left
	jl _ret
	cmp ecx,SDBound.right
	jge _ret
	
	cmp edi,SDBound.top
	jge @F
		mov edi,SDBound.top
	@@:
	cmp eax,SDBound.bottom
	jle @F
		mov eax,SDBound.bottom
	@@:
	sub eax,edi
	jle _ret
	
	imul edi,sTarget_Data.linesize
	shl ecx,2
	add edi,sTarget_Data.bits
	add edi,ecx
	mov ecx,dwColor
	align 16
	@@:
		mov [edi],ecx
		add edi,sTarget_Data.linesize
	dec eax
	jnz @B
	
_ret:	ret
sDrawLineV endp




sDrawRect proc PUBLIC UseAll x,y,wid,hei,dwColor
	local extraDest
	CHECKDRAWRECT
	COMPUTEBLTBITS	
	mov eax,dwColor
	mov esi,wid
	mov ebx,hei
	mov edx,extraDest
	cld
	
	align 16
	@@:
		mov ecx,esi
		rep stosd
		
		add edi,edx
		dec ebx
	jnz @B
	
	
	
	
_ret:	ret
sDrawRect endp


sDrawRectFrame proc PUBLIC UseAll x,y,wid,hei,dwColor
	cmp wid,0
	jle _ret
	cmp hei,0
	jle _ret
	invoke sDrawLineH,x,y,wid,dwColor ; top
	
	mov eax,y
	add eax,hei
	dec eax
	invoke sDrawLineH,x,eax,wid,dwColor ; bottom
	
	invoke sDrawLineV,x,y,hei,dwColor ; left
	
	mov eax,x
	add eax,wid
	dec eax
	invoke sDrawLineV,eax,y,hei,dwColor ; right
	
_ret:	ret
sDrawRectFrame endp

sDrawRectFrame3D proc PUBLIC UseAll x,y,wid,hei,dwColor,dwLightColor,dwDarkColor
	;-------[ if too small ]---------------------[
	cmp wid,0
	jle _ret
	cmp hei,0
	jle _ret
	.if wid<3 || hei<3
		invoke sDrawRect,x,y,wid,hei,dwColor
		jmp _ret
	.endif
	;--------------------------------------------/
	mov ecx,wid
	mov edx,hei
	mov esi,x
	mov edi,y
	dec edx
	invoke sDrawLineH,esi,edi,ecx,dwLightColor ; top line
	inc edi
	dec edx
	dec ecx
	invoke sDrawLineV,esi,edi,edx,dwLightColor ; left line
	inc esi
	dec ecx
	invoke sDrawRect,esi,edi,ecx,edx,dwColor    ; base color
	add esi,ecx
	invoke sDrawLineV,esi,edi,edx,dwDarkColor  ; right line
	add edi,edx
	invoke sDrawLineH,x,edi,wid,dwDarkColor    ; bottom line
	
	
_ret:	ret
sDrawRectFrame3D endp	
;=======/


;=====[[ sBlt   - normal >>===\
sBlt proc PUBLIC UseAll x,y,wid,hei,x2,y2
	local extraDest,extraSrc
	local Alpha,invAlpha,wid2
	invoke FixupSBLTparams,addr x
	jz _ret
	
	COMPUTEBLTBITS2
	
	
	.if !(sSource_Data.dwFlags & SDRAWSPRITE_HASALPHA)
		;----------[ draw a normal solid bitmap ]-------[
		mov ebx,hei
		mov eax,extraSrc
		mov edx,extraDest
		align 16
		@@:
			mov ecx,wid
			rep movsd
			
			add esi,eax
			add edi,edx
			dec ebx
		jnz @B
		;-----------------------------------------------/
		ret
		
	.else
		
	    .if sSource_Data.dwFlags & SDRAWSPRITE_PREMULALPHA
		;---------[ draw a bitmap that has premultiplied alpha-channel ]-------------------------[
		@@:
		m2m wid2,wid
		align 16
			_nextpix:
			mov eax,[esi]
			mov ecx,[edi]
			
			mov ebx,eax
			shr ebx,24
			jz _zeroalpha
			sub ebx,256
			neg ebx
			
			mov edx,ecx
			
			and ecx,0FF00FFh
			and edx,000FF00h
			imul ecx,ebx
			imul edx,ebx
			and ecx,0FF00FF00h
			and edx,000FF0000h
			or ecx,edx
			shr ecx,8
			add ecx,eax
			mov [edi],ecx
			
			_zeroalpha:
			
			add esi,4
			add edi,4
			dec wid2
			jnz _nextpix
			
			add esi,extraSrc
			add edi,extraDest
			dec hei
		jnz @B
		ret
		;----------------------------------------------------------------------------------------/
	    .else
		;-----[ draw a bitmap that has alpha-channel ]-------[
		@@:
		m2m wid2,wid
		align 16
			_nextpix2:
			mov eax,[esi]
			mov ecx,[edi]
			;-----[ get alpha ]-----[
			mov edx,256
			mov ebx,eax
			shr ebx,24
			jz _zeroalpha2
			sub edx,ebx
			mov Alpha,ebx
			mov invAlpha,edx
			;-----------------------/
			
			mov ebx,eax
			mov edx,ecx
			
			and eax,0FF00FFh
			and ecx,0FF00FFh
			and ebx,000FF00h
			and edx,000FF00h
			imul eax,Alpha
			imul ecx,invAlpha
			imul ebx,Alpha
			imul edx,invAlpha
			add eax,ecx
			add ebx,edx
			and eax,0FF00FF00h
			and ebx,000FF0000h
			or eax,ebx
			shr eax,8
			mov [edi],eax
			
			
			
			_zeroalpha2:
			
			
			
			add esi,4
			add edi,4
			dec wid2
			jnz _nextpix2
			
			add esi,extraSrc
			add edi,extraDest
			dec hei
		jnz @B
		ret
		;----------------------------------------------------/
	    .endif
		
	.endif
	
	
_ret:	ret
sBlt endp
;=======/


sBltTile proc PUBLIC uses eax ebx ecx edx TileX,TileY,TileWidth,TileHeight,SpriteX,SpriteY,SpriteWid,SpriteHei,StartX,StartY
	invoke sdEnterClip,TileX,TileY,TileWidth,TileHeight
	
	neg StartX
	neg StartY
	
	mov edx,StartY
	.while edx<TileHeight
		mov ecx,StartX
		.while ecx<TileWidth
			invoke sBlt,ecx,edx,SpriteWid,SpriteHei,SpriteX,SpriteY
			add ecx,SpriteWid
		.endw
		add edx,SpriteHei
	.endw
	
	invoke sdLeaveClip
	ret
sBltTile endp




;=====[[ sdGet/Set/SetPixelA >>===\
sdGetPixel proc PUBLIC uses ecx edx x,y
	mov ecx,x
	mov edx,y
	add ecx,SDDrawOffs.x
	add edx,SDDrawOffs.y
	xor eax,eax
	
	cmp ecx,SDBound.left
	jl _ret
	cmp ecx,SDBound.right
	jge _ret
	cmp edx,SDBound.top
	jl _ret
	cmp edx,SDBound.bottom
	jge _ret
	imul edx,sTarget_Data.wid
	mov eax,sTarget_Data.bits
	add ecx,edx
	mov eax,[eax+ecx*4]
	and eax,0FFFFFFh
	
_ret:	ret
sdGetPixel endp

sdSetPixel proc PUBLIC uses eax ecx edx x,y,dwColor
	mov ecx,x
	mov edx,y
	add ecx,SDDrawOffs.x
	add edx,SDDrawOffs.y
	xor eax,eax
	
	cmp ecx,SDBound.left
	jl _ret
	cmp ecx,SDBound.right
	jge _ret
	cmp edx,SDBound.top
	jl _ret
	cmp edx,SDBound.bottom
	jge _ret
	imul edx,sTarget_Data.wid
	mov eax,sTarget_Data.bits
	add ecx,edx
	mov edx,dwColor
	mov [eax+ecx*4],edx
	
_ret:	ret
sdSetPixel endp

sdSetPixelA proc PUBLIC uses eax ecx ebx edx edi x,y,dwColor,Alpha
	cmp Alpha,0
	jle _ret
	mov ecx,x
	mov edx,y
	add ecx,SDDrawOffs.x
	add edx,SDDrawOffs.y
	xor eax,eax
	
	cmp ecx,SDBound.left
	jl _ret
	cmp ecx,SDBound.right
	jge _ret
	cmp edx,SDBound.top
	jl _ret
	cmp edx,SDBound.bottom
	jge _ret
	
	
	
	;---[ compute edi ]----------------[
	imul edx,sTarget_Data.wid
	mov edi,sTarget_Data.bits
	add ecx,edx
	lea edi,[edi+ecx*4]
	;----------------------------------/
	;---[ compute invAlpha ]---------[
	.if Alpha>255
		push dwColor
		pop dword ptr[edi]
		jmp _ret
	.endif
	mov edx,256
	sub edx,Alpha
	mov y,edx ; y = invAlpha
	;--------------------------------/
	
	
	
	mov eax,dwColor
	mov ecx,[edi]
	mov ebx,eax
	mov edx,ecx
	and eax,0FF00FFh
	and ecx,0FF00FFh
	and ebx,000FF00h
	and edx,000FF00h
	imul eax,Alpha
	imul ecx,y;invAlpha
	imul ebx,Alpha
	imul edx,y;invAlpha
	add eax,ecx
	add ebx,edx
	and eax,0FF00FF00h
	and ebx,000FF0000h
	or eax,ebx
	shr eax,8
	mov [edi],eax
	
	
_ret:	ret
sdSetPixelA endp
;=======/


;=====[[ sDrawLine - normal >>===\
SD_DRAWLINE_EXTRALAPHA equ 64
sDrawLine proc PUBLIC UseAll x,y,x2,y2,dwColor
	local idx,idy
	local zdx,zdy
	
	;-----[ check if completely outside cliprect ]-----\
	mov esi,SDDrawOffs.x
	mov edi,SDDrawOffs.y
	mov eax,x
	mov ebx,y
	mov ecx,x2
	mov edx,y2
	add eax,esi
	add ebx,edi
	add ecx,esi
	add edx,edi
	cmp eax,ecx
	jle @F
	xchg eax,ecx
	@@:
	cmp ebx,edx
	jle @F
	xchg ebx,edx
	@@:
	; eax=minx, ebx=miny, ecx=maxx, edx=maxy
	cmp eax,SDBound.right
	jg _ret
	cmp ebx,SDBound.bottom
	jg _ret
	cmp ecx,SDBound.left
	jl _ret
	cmp edx,SDBound.top
	jl _ret
	;--------------------------------------------------/
	
	
	;--------[ check if too long ]---------------\
	sub ecx,eax
	sub edx,ebx
	add ecx,edx
	.if ecx>100
		mov eax,x
		mov ecx,y
		add eax,x2
		add ecx,y2
		sar eax,1
		sar ecx,1
		invoke sDrawLine,x,y,eax,ecx,dwColor
		invoke sDrawLine,eax,ecx,x2,y2,dwColor
		ret
	.endif
	;--------------------------------------------/
	
	
	
	mov idx,-1
	mov idy,-1
	mov eax,x
	sub eax,x2
	mov zdx,eax
	.if sign?
		neg eax
		neg idx
	.endif
	mov edx,y
	sub edx,y2
	mov zdy,edx
	.if sign?
		neg edx
		neg idy
	.endif
	
	.if zdx==0 && zdy==0
		invoke sdSetPixel,x,y,dwColor
		ret
	.endif
	
	.if eax<=edx	
		;mov dwColor,255
		shl zdx,16
		fild zdx
		fidiv zdy
		fimul idy
		fistp idx
		
		mov eax,x
		shl eax,16
		mov ecx,y
		.while ecx!=y2
			mov edx,eax
			sar edx,16
			movzx ebx,ah
			push ebx
			sub ebx,255+SD_DRAWLINE_EXTRALAPHA
			neg ebx
			invoke sdSetPixelA,edx,ecx,dwColor,ebx
			pop ebx
			inc edx
			add ebx,SD_DRAWLINE_EXTRALAPHA
			invoke sdSetPixelA,edx,ecx,dwColor,ebx
			
			add eax,idx
			add ecx,idy
		.endw
		ret
	.else
		shl zdy,16
		fild zdy
		fidiv zdx
		fimul idx
		fistp idy
		
		mov eax,x
		mov ecx,y
		shl ecx,16
		.while eax!=x2
			mov edx,ecx
			sar edx,16
			movzx ebx,ch
			push ebx
			sub ebx,255+SD_DRAWLINE_EXTRALAPHA
			neg ebx
			invoke sdSetPixelA,eax,edx,dwColor,ebx
			pop ebx
			inc edx 
			add ebx,SD_DRAWLINE_EXTRALAPHA
			invoke sdSetPixelA,eax,edx,dwColor,ebx
			
			add eax,idx
			add ecx,idy
		.endw		
		ret
	.endif
		
	
	
	
_ret:	ret
sDrawLine endp
;=======/

;=====<< sDrawFastLine >>===\
sDrawFastLine proc PUBLIC UseAll x0,y0,x1,y1,dwColor
	local steep
	local stepy,stepx
	
	;-----[ check if completely outside cliprect ]-----\
	mov esi,SDDrawOffs.x
	mov edi,SDDrawOffs.y
	mov eax,x0
	mov ebx,y0
	mov ecx,x1
	mov edx,y1
	.if eax==ecx && ebx==edx
		invoke sdSetPixel,eax,ebx,dwColor
	.endif	
	add eax,esi
	add ebx,edi
	add ecx,esi
	add edx,edi
	cmp eax,ecx
	jle @F
	xchg eax,ecx
	@@:
	cmp ebx,edx
	jle @F
	xchg ebx,edx
	@@:
	
	; eax=minx, ebx=miny, ecx=maxx, edx=maxy
	cmp eax,SDBound.right
	jg _ret
	cmp ebx,SDBound.bottom
	jg _ret
	cmp ecx,SDBound.left
	jl _ret
	cmp edx,SDBound.top
	jl _ret
	
	sub x0,esi
	sub y0,esi
	sub x1,esi
	sub y1,esi
	;--------------------------------------------------/
	
	
	;------[ check steepness ]-----\
	mov eax,y0
	sub eax,y1
	mov edx,x0
	sub edx,x1
	mov ecx,eax
	sar ecx,31
	add eax,ecx
	xor eax,ecx
	mov ecx,edx
	sar ecx,31
	add edx,ecx
	xor edx,ecx
	cmp eax,edx
	
	mov steep,0
	mov stepx,1
	mov stepy,1
	
	mov eax,x0  ; eax = x0
	mov ebx,y0  ; ebx = y0 
	mov ecx,x1  ; ecx = x1
	mov edx,y1  ; edx = y1
	
	.if !SIGN? ; abs(y1 - y0) > abs(x1 - x0)
		mov steep,1
		xchg eax,ebx
		xchg ecx,edx
	.endif
	
	cmp eax,ecx
	jle @F
		neg stepx
	@@:
	mov x0,eax
	mov y0,ebx
	mov x1,ecx
	mov y1,edx
	;------------------------------/
	
	sub ecx,eax ; ecx = deltax
	mov esi,ecx
	sar esi,31
	add ecx,esi
	xor ecx,esi
	mov edi,ecx
	shr edi,1   ; edi = deltax/2
	sub edx,ebx
	mov esi,edx
	sar esi,31
	add edx,esi
	xor edx,esi ; edx = deltay
	
	xor esi,esi ; esi = error
	
	
	cmp ebx,y1
	jl @F
		neg stepy
	@@:
	
	; now   EAX=x0, EBX=y0, ECX=deltax, EDX=deltay, ESI=error, EDI=deltax/2
	
	
	align 16
	next_X:
	cmp eax,x1
	je _ret
	.if steep		
		invoke sdSetPixel,ebx,eax,dwColor
	.else
		invoke sdSetPixel,eax,ebx,dwColor
	.endif
	add eax,stepx
	
	add esi,edx ; error+=deltay
	cmp esi,edi
	jl next_X
	add ebx,stepy
	sub esi,ecx
	jmp next_X
	
	
	
_ret:	ret
sDrawFastLine endp
;=======/


;=====<< sDrawLineCustom >>===\
sDrawLineCustom proc PUBLIC UseAll x0,y0,x1,y1,pfCallback,dwWidth,dwColor
	local steep
	local stepy,stepx
	
	;-----[ check if completely outside cliprect ]-----\
	mov esi,SDDrawOffs.x
	mov edi,SDDrawOffs.y
	mov eax,x0
	mov ebx,y0
	mov ecx,x1
	mov edx,y1
	add eax,esi
	add ebx,edi
	add ecx,esi
	add edx,edi
	cmp eax,ecx
	jle @F
	xchg eax,ecx
	@@:
	cmp ebx,edx
	jle @F
	xchg ebx,edx
	@@:
	mov esi,dwWidth
	mov edi,esi
	shr esi,1
	sub edi,esi
	
	sub eax,esi
	sub ebx,esi
	add ecx,edi
	add edx,edi
	
	; eax=minx, ebx=miny, ecx=maxx, edx=maxy
	cmp eax,SDBound.right
	jg _ret
	cmp ebx,SDBound.bottom
	jg _ret
	cmp ecx,SDBound.left
	jl _ret
	cmp edx,SDBound.top
	jl _ret
	
	sub x0,esi
	sub y0,esi
	sub x1,esi
	sub y1,esi
	;--------------------------------------------------/
	
	
	;------[ check steepness ]-----\
	mov eax,y0
	sub eax,y1
	mov edx,x0
	sub edx,x1
	mov ecx,eax
	sar ecx,31
	add eax,ecx
	xor eax,ecx
	mov ecx,edx
	sar ecx,31
	add edx,ecx
	xor edx,ecx
	cmp eax,edx
	
	mov steep,0
	mov stepx,1
	mov stepy,1
	
	mov eax,x0  ; eax = x0
	mov ebx,y0  ; ebx = y0 
	mov ecx,x1  ; ecx = x1
	mov edx,y1  ; edx = y1
	
	.if !SIGN? ; abs(y1 - y0) > abs(x1 - x0)
		mov steep,1
		xchg eax,ebx
		xchg ecx,edx
	.endif
	
	cmp eax,ecx
	jle @F
		neg stepx
	@@:
	mov x0,eax
	mov y0,ebx
	mov x1,ecx
	mov y1,edx
	;------------------------------/
	
	sub ecx,eax ; ecx = deltax
	mov esi,ecx
	sar esi,31
	add ecx,esi
	xor ecx,esi
	mov edi,ecx
	shr edi,1   ; edi = deltax/2
	sub edx,ebx
	mov esi,edx
	sar esi,31
	add edx,esi
	xor edx,esi ; edx = deltay
	
	xor esi,esi ; esi = error
	
	
	cmp ebx,y1
	jl @F
		neg stepy
	@@:
	
	; now   EAX=x0, EBX=y0, ECX=deltax, EDX=deltay, ESI=error, EDI=deltax/2
	
	
	align 16
	next_X:
	cmp eax,x1
	je _ret
	push dwColor
	.if steep
		push eax
		push ebx
	.else
		push ebx
		push eax
	.endif
	call pfCallback
	
	add eax,stepx
	
	add esi,edx ; error+=deltay
	cmp esi,edi
	jl next_X
	add ebx,stepy
	sub esi,ecx
	jmp next_X
	
	
_ret:	ret
sDrawLineCustom endp
;=======/


;=====<< sDrawBSpline >>===\
.data
	BSplineShader 	dd 0
	BSplineShadeWid dd 1
.code
	
sDrawBSpline proc PUBLIC UseAll pSpline:ptr SDSPLINE,numPoints,dwColor
	local xa,xb,xc
	local ya,yb,yc
	local deltaT:real8,curT:real8
	local curX,curY,nX,nY
	
	mov ecx,pSpline
	test ecx,ecx
	jz _ret
	assume ecx:ptr SDSPLINE
	
	; C = 3.0 * (cp[1] - cp[0]);
	mov eax,[ecx].p1.x
	mov edx,[ecx].p1.y
	sub eax,[ecx].p0.x
	sub edx,[ecx].p0.y
	lea eax,[eax+eax*2]
	lea edx,[edx+edx*2]
	mov xc,eax
	mov yc,edx
	
	; B = 3.0 * (cp[2] - cp[1]) - C;
	mov eax,[ecx].p2.x
	mov edx,[ecx].p2.y
	sub eax,[ecx].p1.x
	sub edx,[ecx].p1.y
	lea eax,[eax+eax*2]
	lea edx,[edx+edx*2]
	sub eax,xc
	sub edx,yc
	mov xb,eax
	mov yb,edx
	
	; A = cp[3].x - cp[0].x - cx - bx;
	mov eax,[ecx].p3.x
	mov edx,[ecx].p3.y
	sub eax,[ecx].p0.x
	sub edx,[ecx].p0.y
	sub eax,xc
	sub edx,yc
	sub eax,xb
	sub edx,yb
	mov xa,eax
	mov ya,edx
	
	;--------[ compute numPoints if necessary ]----------\
	.if numPoints==0
		;----[ compute average point of p1 & p2 ]--\
		mov eax,[ecx].p2.x
		mov edx,[ecx].p2.y
		add eax,[ecx].p1.x
		add edx,[ecx].p1.y
		sar eax,1
		sar edx,1
		mov nX,eax ; store it temporarily in nX:nY
		mov nY,eax
		;------------------------------------------/
		
		;----[ compute sqr of len p0:pN ]--\
		fild [ecx].p0.x
		fisub nX
		fmul ST,ST
		fild [ecx].p0.y
		fisub nY
		fmul ST,ST
		fadd
		;----------------------------------/
		;----[ compute sqr of len p3:pN ]--\
		fild [ecx].p3.x
		fisub nX
		fmul ST,ST
		fild [ecx].p3.y
		fisub nY
		fmul ST,ST
		fadd
		;----------------------------------/
		fadd
		fsqrt
		fistp numPoints
		shr numPoints,3
		add numPoints,4		
	.endif
	;----------------------------------------------------/
	
	
	
	
	fld1
	fidiv numPoints
	fst deltaT
	fstp curT
	m2m curX,[ecx].p0.x
	m2m curY,[ecx].p0.y
	
	@@:
		; nX = 	(ax * tCubed) + (bx * tSquared) + (cx * t) + cp[0].x;
		fild [ecx].p0.x
		fild xc
		fmul curT
		fadd
		fild xb
		fmul curT
		fmul curT
		fadd
		fild xa
		fmul curT
		fmul curT
		fmul curT
		fadd
		fistp nX
		
		; nY = 	(ay * tCubed) + (by * tSquared) + (cy * t) + cp[0].y;
		fild [ecx].p0.y
		fild yc
		fmul curT
		fadd
		fild yb
		fmul curT
		fmul curT
		fadd
		fild ya
		fmul curT
		fmul curT
		fmul curT
		fadd
		fistp nY
		
		.if !BSplineShader
			invoke sDrawLine,curX,curY,nX,nY,dwColor
		.else
			invoke sDrawLineCustom,curX,curY,nX,nY,BSplineShader,BSplineShadeWid,dwColor
		.endif
		
		
		
		m2m curX,nX
		m2m curY,nY
		fld curT
		fadd deltaT
		fstp curT
	dec numPoints
	jnz @B
	
	
	
	assume ecx:nothing
_ret:	ret
sDrawBSpline endp

sDrawBSplineShade proc PUBLIC pSpline:ptr SDSPLINE,numPoints,dwColor,pShadeFunc,ShadeWid
	m2m BSplineShader,pShadeFunc
	m2m BSplineShadeWid,ShadeWid
	
	invoke sDrawBSpline,pSpline,numPoints,dwColor
	
	mov BSplineShader,0
	mov BSplineShadeWid,1
	ret
sDrawBSplineShade endp
;=======/


sBltTrans proc PUBLIC UseAll x,y,wid,hei,x2,y2
	local Alpha,invAlpha,wid2
	invoke FixupSBLTparams,addr x
	jz _ret
	
	COMPUTEBLTBITS3
	
	sub esi,4
	sub edi,4
	mov ebx,SD_TransparentColor
	
	nextline:
		mov ecx,wid
		align 16
		@@:
			mov eax,[esi+ecx*4]
			and eax,0FFFFFFh
			.if eax!=ebx
				mov [edi+ecx*4],eax
			.endif
		dec ecx
		jnz @B
		
		add esi,sSource_Data.linesize
		add edi,sTarget_Data.linesize
		dec hei
	jnz nextline
	
		
	
_ret:	ret
sBltTrans endp


sBltTransAlpha proc PUBLIC UseAll x,y,wid,hei,x2,y2,Alpha
	local extraDest,extraSrc
	local wid2,invAlpha,Alpha2
	;---[ check alpha ]--------------------[
	cmp Alpha,0
	jle _ret
	.if Alpha>255
		invoke sBltTrans,x,y,wid,hei,x2,y2
		jmp _ret
	.endif
	;--------------------------------------/
	
	invoke FixupSBLTparams,addr x
	jz _ret
	
	COMPUTEBLTBITS2
	
	
		
	    mov eax,256
	    sub eax,Alpha
	    mov invAlpha,eax
	    @@:
		m2m wid2,wid
		align 16
		_nextpix:
		mov eax,[esi]
		mov ecx,[edi]
		mov ebx,eax
		xor eax,SD_TransparentColor
		mov edx,ecx
		shl eax,8
		jz skippix
		mov eax,ebx
		and eax,0FF00FFh
		and ecx,0FF00FFh
		and ebx,000FF00h
		and edx,000FF00h
		imul eax,Alpha
		imul ecx,invAlpha
		imul ebx,Alpha
		imul edx,invAlpha
		add eax,ecx
		add ebx,edx
		and eax,0FF00FF00h
		and ebx,000FF0000h
		add eax,ebx
		shr eax,8
		mov [edi],eax
		
		
		
		; out = (dcolor*(256-alpha) + color*alpha)/256 = 
		;  dcolor*256 - dcolor*alpha + color*alpha = dcolor*256 + alpha*(color-dcolor)
		
		skippix:
		
		
		
		add esi,4
		add edi,4
		dec wid2
		jnz _nextpix
		
		add esi,extraSrc
		add edi,extraDest
		dec hei
	    jnz @B
	
	
_ret:	ret
sBltTransAlpha endp



;=====<< sBltAlpha >>===\
sBltAlpha proc PUBLIC UseAll x,y,wid,hei,x2,y2,Alpha
	local extraDest,extraSrc
	local wid2,invAlpha,Alpha2
	;---[ check alpha ]--------------------[
	cmp Alpha,0
	jle _ret
	.if Alpha>255
		invoke sBlt,x,y,wid,hei,x2,y2
		jmp _ret
	.endif
	;--------------------------------------/
	
	invoke FixupSBLTparams,addr x
	jz _ret
	
	COMPUTEBLTBITS2
	
	
		
	.if !(sSource_Data.dwFlags & SDRAWSPRITE_HASALPHA)
	    mov eax,256
	    sub eax,Alpha
	    mov invAlpha,eax
	    @@:
		m2m wid2,wid
		align 16
		_nextpix:
		mov eax,[esi]
		mov ecx,[edi]
		mov ebx,eax
		mov edx,ecx
		and eax,0FF00FFh
		and ecx,0FF00FFh
		and ebx,000FF00h
		and edx,000FF00h
		imul eax,Alpha
		imul ecx,invAlpha
		imul ebx,Alpha
		imul edx,invAlpha
		add eax,ecx
		add ebx,edx
		and eax,0FF00FF00h
		and ebx,000FF0000h
		add eax,ebx
		shr eax,8
		mov [edi],eax
		
		
		
		; out = (dcolor*(256-alpha) + color*alpha)/256 = 
		;  dcolor*256 - dcolor*alpha + color*alpha = dcolor*256 + alpha*(color-dcolor)
		
		
		
		
		add esi,4
		add edi,4
		dec wid2
		jnz _nextpix
		
		add esi,extraSrc
		add edi,extraDest
		dec hei
	    jnz @B
	.else
		;-----[ draw a bitmap that has alpha-channel ]-------[
		@@:
		m2m wid2,wid
		align 16
			_nextpix2:
			mov eax,[esi]
			mov ecx,[edi]
			;-----[ get alpha ]-----[
			mov edx,256
			mov ebx,eax
			shr ebx,24
			jz _zeroalpha2
			imul ebx,Alpha
			shr ebx,8
			jz _zeroalpha2
			sub edx,ebx
			mov Alpha2,ebx
			mov invAlpha,edx
			;-----------------------/
			
			mov ebx,eax
			mov edx,ecx
			
			and eax,0FF00FFh
			and ecx,0FF00FFh
			and ebx,000FF00h
			and edx,000FF00h
			imul eax,Alpha2
			imul ecx,invAlpha
			imul ebx,Alpha2
			imul edx,invAlpha
			add eax,ecx
			add ebx,edx
			and eax,0FF00FF00h
			and ebx,000FF0000h
			or eax,ebx
			shr eax,8
			mov [edi],eax
						
			
			_zeroalpha2:
			
			
			
			add esi,4
			add edi,4
			dec wid2
			jnz _nextpix2
			
			add esi,extraSrc
			add edi,extraDest
			dec hei
		jnz @B
		ret
		;----------------------------------------------------/
	    
	.endif

	
_ret:	ret
sBltAlpha endp

;=======/



sDrawRectAlpha proc PUBLIC UseAll x,y,wid,hei,dwColor,Alpha	
	
	;----[ check params ]------------------------[
	cmp Alpha,0
	jle _ret
	.if Alpha>255
		invoke sDrawRect,x,y,wid,hei,dwColor
		jmp _ret
	.endif
	;--------------------------------------------/
	
	CHECKDRAWRECT
	COMPUTEBLTBITS1
	
	
	;---[ premultiply dwColor ]---[
	mov eax,dwColor
	mov ebx,eax
	and eax,0FF00FFh
	and ebx,000FF00h
	imul eax,Alpha
	imul ebx,Alpha
	and eax,0FF00FF00h
	and ebx,000FF0000h
	or eax,ebx
	shr eax,8
	mov dwColor,eax
	;-----------------------------/
	
	sub edi,4
	mov ebx,256
	sub ebx,Alpha ; ebx = invAlpha
	
	
	
	.if Alpha!=128
		
		nextline:
			mov ecx,wid
			align 16
			@@:
				mov eax,[edi+ecx*4]
				mov edx,eax
				and eax,0FF00FFh
				and edx,000FF00h
				imul eax,ebx
				imul edx,ebx
				and eax,0FF00FF00h
				and edx,000FF0000h
				or eax,edx
				shr eax,8
				add eax,dwColor
				mov [edi+ecx*4],eax
			dec ecx
			jnz @B
			
			add edi,sTarget_Data.linesize
			dec hei
		jnz nextline
		ret
	.else	; Alpha=128
		
		mov edx,dwColor
		mov ebx,7F7F7Fh
		
		nextline2:
			mov ecx,wid
			align 16
			@@:
				mov eax,[edi+ecx*4]
				shr eax,1
				and eax,ebx
				add eax,edx
				mov [edi+ecx*4],eax
			dec ecx
			jnz @B
			
			add edi,sTarget_Data.linesize
			dec hei
		jnz nextline2
		
	.endif	
	
_ret:	ret
sDrawRectAlpha endp



sDrawLineH_HalfAlpha proc PUBLIC uses eax edx ecx edi x,y,wid,dwColor
	mov ecx,x
	mov edi,y
	mov eax,wid
	add ecx,SDDrawOffs.x
	add edi,SDDrawOffs.y
	add eax,ecx
	cmp edi,SDBound.top
	jl _ret	
	cmp edi,SDBound.bottom
	jge _ret
	
	cmp ecx,SDBound.left
	jge @F
		mov ecx,SDBound.left
	@@:
	cmp eax,SDBound.right
	jle @F
		mov eax,SDBound.right
	@@:
	sub eax,ecx
	jle _ret
	imul edi,sTarget_Data.linesize
	shl ecx,2
	add edi,sTarget_Data.bits
	add edi,ecx
	sub edi,4
	mov ecx,dwColor
	and ecx,0FEFEFEh
	
	
	align 16
	@@:
		mov edx,[edi+eax*4]
		and edx,0FEFEFEh
		add edx,ecx
		shr edx,1
		mov [edi+eax*4],edx
	dec eax
	jnz @B
	ret
		
_ret:	ret
sDrawLineH_HalfAlpha endp


sDrawLineV_HalfAlpha proc PUBLIC uses eax edx ecx edi x,y,hei,dwColor
	mov ecx,x
	mov edi,y
	mov eax,hei
	add ecx,SDDrawOffs.x
	add edi,SDDrawOffs.y
	add eax,edi
	
	cmp ecx,SDBound.left
	jl _ret
	cmp ecx,SDBound.right
	jge _ret
	
	cmp edi,SDBound.top
	jge @F
		mov edi,SDBound.top
	@@:
	cmp eax,SDBound.bottom
	jle @F
		mov eax,SDBound.bottom
	@@:
	sub eax,edi
	jle _ret
	
	imul edi,sTarget_Data.linesize
	shl ecx,2
	add edi,sTarget_Data.bits
	add edi,ecx
	mov ecx,dwColor
	and ecx,0FEFEFEh
	
	align 16
	@@:
		mov edx,[edi]
		and edx,0FEFEFEh
		add edx,ecx
		shr edx,1
		mov [edi],edx
		add edi,sTarget_Data.linesize
	dec eax
	jnz @B
	
_ret:	ret
sDrawLineV_HalfAlpha endp


;=====[[ sBltAdd+Fade >>===\
sBltAdd proc PUBLIC UseAll x,y,wid,hei,x2,y2
	local extraDest,extraSrc
	local Num16px,Num1px
	invoke FixupSBLTparams,addr x
	jz _ret
	
	COMPUTEBLTBITS2
	
	mov eax,wid
	shr eax,4
	mov Num16px,eax
	mov eax,wid
	and eax,15
	mov Num1px,eax
	
	;----------[ draw a normal solid bitmap ]-------[
	nextline:
		mov ecx,Num16px
		.if ecx
			align 8
			@@:
			movq mm0,[edi]
			movq mm1,[esi]
			movq mm2,[edi+8]
			movq mm3,[esi+8]
			movq mm4,[edi+16]
			movq mm5,[esi+16]
			movq mm6,[edi+24]
			movq mm7,[esi+24]
			paddusb mm0,mm1
			paddusb mm2,mm3
			paddusb mm4,mm5
			paddusb mm6,mm7
			movq [edi],mm0
			movq [edi+8],mm2
			movq [edi+16],mm4
			movq [edi+24],mm6
			
			add esi,32
			add edi,32
			
			movq mm0,[edi]
			movq mm1,[esi]
			movq mm2,[edi+8]
			movq mm3,[esi+8]
			movq mm4,[edi+16]
			movq mm5,[esi+16]
			movq mm6,[edi+24]
			movq mm7,[esi+24]
			paddusb mm0,mm1
			paddusb mm2,mm3
			paddusb mm4,mm5
			paddusb mm6,mm7
			movq [edi],mm0
			movq [edi+8],mm2
			movq [edi+16],mm4
			movq [edi+24],mm6
			add esi,32
			add edi,32
			dec ecx
			jnz @B
		.endif
		
		
		
		mov ecx,Num1px
		.if ecx
			@@:
			movd mm0,[esi]
			movd mm1,[edi]
			paddusb mm0,mm1
			movd [edi],mm0
			add esi,4
			add edi,4
			dec ecx
			jnz @B
		.endif
		
			
		
			
	add esi,extraSrc
	add edi,extraDest
	dec hei
	jnz nextline
	;-----------------------------------------------/
	emms	
		
	
_ret:	ret
sBltAdd endp


sBltAddFade proc PUBLIC UseAll x,y,wid,hei,x2,y2,Fader
	local extraDest,extraSrc
	cmp Fader,0
	jle _ret
	.if Fader>255
		invoke sBltAdd,x,y,wid,hei,x2,y2
		jmp _ret
	.endif
	
	
	invoke FixupSBLTparams,addr x
	jz _ret
	
	COMPUTEBLTBITS2
	
	
	
	;--[ set masks ]--[
	mov eax,0FF00FFh
	mov ecx,000FF00h
	movd mm6,eax
	movd mm7,ecx
	mov eax,Fader
	mov edx,eax
	shl edx,16
	or eax,edx
	movd mm5,eax
	;-----------------/
	;----------[ draw a normal solid bitmap ]-------[
	nextline:
		mov ecx,wid
		align 16
		@@:
			movd mm0,[esi]
			movd mm1,[edi]
			movq mm2,mm0
			pand mm0,mm6
			pand mm2,mm7
			psrad mm2,8
			pmullw mm0,mm5
			pmullw mm2,mm5
			psraw mm0,8
			
			pand mm0,mm6
			pand mm2,mm7
			paddusb mm1,mm0
			paddusb mm1,mm2
			movd [edi],mm1
		add esi,4
		add edi,4
		dec ecx
		jnz @B		
			
	add esi,extraSrc
	add edi,extraDest
	dec hei
	jnz nextline
	;-----------------------------------------------/
	emms	
		
	
_ret:	ret
sBltAddFade endp

;=======/

sDrawRectAddFade proc PUBLIC UseAll x,y,wid,hei,dwColor,Alpha
	
	;----[ check params ]------------------------[
	cmp Alpha,0
	jle _ret
	.if Alpha>256
		mov Alpha,256
	.endif
	;--------------------------------------------/
	
	CHECKDRAWRECT
	COMPUTEBLTBITS1
	
	
	;---[ premultiply dwColor ]---[
	mov eax,dwColor
	mov ebx,eax
	and eax,0FF00FFh
	and ebx,000FF00h
	imul eax,Alpha
	imul ebx,Alpha
	and eax,0FF00FF00h
	and ebx,000FF0000h
	or eax,ebx
	shr eax,8
	movd mm1,eax
	;-----------------------------/
	
	
	sub edi,4
	
	
	
	align 16
	nextline:
		mov ecx,wid
		align 16
		@@:
			movd mm0,[edi+ecx*4]
			paddusb mm0,mm1
			movd [edi+ecx*4],mm0
		dec ecx
		jnz @B
		
		sub edi,sTarget_Data.linesize
		dec hei
	jnz nextline
	
	emms
	
_ret:	ret
sDrawRectAddFade endp

sDrawLineHAdd proc PUBLIC uses eax edx ecx edi x,y,wid,dwColor
	mov ecx,x
	mov edi,y
	mov eax,wid
	add ecx,SDDrawOffs.x
	add edi,SDDrawOffs.y
	add eax,ecx
	cmp edi,SDBound.top
	jl _ret	
	cmp edi,SDBound.bottom
	jge _ret
	
	cmp ecx,SDBound.left
	jge @F
		mov ecx,SDBound.left
	@@:
	cmp eax,SDBound.right
	jle @F
		mov eax,SDBound.right
	@@:
	sub eax,ecx
	jle _ret
	imul edi,sTarget_Data.linesize
	shl ecx,2
	add edi,sTarget_Data.bits
	add edi,ecx
	sub edi,4
	mov ecx,dwColor
	and ecx,0FEFEFEh
	movd mm1,ecx
	
	align 16
	@@:
		movd mm0,[edi+eax*4]
		paddusb mm0,mm1
		movd [edi+eax*4],mm0
	dec eax
	jnz @B
	
	emms
		
_ret:	ret
sDrawLineHAdd endp


sDrawLineVAdd proc PUBLIC uses eax edx ecx edi x,y,hei,dwColor
	mov ecx,x
	mov edi,y
	mov eax,hei
	add ecx,SDDrawOffs.x
	add edi,SDDrawOffs.y
	add eax,edi
	
	cmp ecx,SDBound.left
	jl _ret
	cmp ecx,SDBound.right
	jge _ret
	
	cmp edi,SDBound.top
	jge @F
		mov edi,SDBound.top
	@@:
	cmp eax,SDBound.bottom
	jle @F
		mov eax,SDBound.bottom
	@@:
	sub eax,edi
	jle _ret
	
	imul edi,sTarget_Data.linesize
	shl ecx,2
	add edi,sTarget_Data.bits
	add edi,ecx
	mov ecx,dwColor
	and ecx,0FEFEFEh
	movd mm1,ecx
	
	align 16
	@@:
		movd mm0,[edi]
		paddusb mm0,mm1
		movd [edi],mm0
		sub edi,sTarget_Data.linesize
	dec eax
	jnz @B
	emms
	
_ret:	ret
sDrawLineVAdd endp

sBltTint proc PUBLIC UseAll x,y,wid,hei,x2,y2,dwColor
	local extraDest,extraSrc
	local wid2
	local TintRB,TintG
	invoke FixupSBLTparams,addr x
	jz _ret
	
	COMPUTEBLTBITS2
	
	
	;
	;			NOTE
	;
	;		uses only the alpha-channel of source-bitmap
	
	
	mov eax,dwColor
	mov edx,eax
	and eax,0FF00FFh
	and edx,000FF00h
	mov TintRB,eax
	mov TintG,edx
	
	
	
	@@:
	m2m wid2,wid
	align 16
		_nextpix:
		mov eax,[esi]
		mov ecx,[edi]
		
		;-----[ get alpha ]-----[
		shr eax,24
		mov ebx,256
		sub ebx,eax
		; eax = Alpha
		; ebx = invAlpha
		;-----------------------/
		
		
		mov edx,ecx
		
		and ecx,0FF00FFh
		and edx,000FF00h
		imul ecx,ebx
		imul edx,ebx
		mov ebx,eax
		imul eax,TintRB
		imul ebx,TintG
		add eax,ecx
		add ebx,edx
		and eax,0FF00FF00h
		and ebx,000FF0000h
		add eax,ebx
		shr eax,8
		mov [edi],eax
		
		
		
		; out = (dcolor*(256-alpha) + color*alpha)/256 = 
		;  dcolor*256 - dcolor*alpha + color*alpha = dcolor*256 + alpha*(color-dcolor)
		
		
		
		
		add esi,4
		add edi,4
		dec wid2
		jnz _nextpix
		
		add esi,extraSrc
		add edi,extraDest
		dec hei
	jnz @B
	
		
	
	
_ret:	ret
sBltTint endp




sBltTintDirect proc PUBLIC UseAll x,y,wid,hei,x2,y2,dwOriginalColor,dwColor
	local extraDest,extraSrc
	local wid2
	local TintRB,TintG
	local iR,iG,iB
	invoke FixupSBLTparams,addr x
	jz _ret
	
	COMPUTEBLTBITS2
	
	
	;
	;			NOTE
	;
	;	doesn't use the alpha-channel of the source-bitmap
	
	;--[ compute TintRB,TintG ]----[
	mov eax,dwColor
	mov edx,eax
	and eax,0FF00FFh
	and edx,000FF00h
	mov TintRB,eax
	mov TintG,edx
	;------------------------------/
	
	;-----[ compute iR,iG,iB ]-----[
	mov eax,dwOriginalColor
	movzx edx,al
	mov iB,edx
	movzx edx,ah
	mov iG,edx
	shr eax,16
	movzx edx,al
	mov iR,edx
	;------------------------------/
	
	
	_nextline:
	m2m wid2,wid
	align 16
		_nextpix:
		mov eax,[esi]
		
		
		;---[ fetch sR,sG,sB ]--[
		movzx ecx,al
		sub ecx,iB
		jge @F
			neg ecx
		@@:	
		movzx edx,ah
		sub edx,iG
		jge @F
			neg edx
		@@:
		add ecx,edx
		shr eax,16
		movzx edx,al
		sub edx,iR
		jge @F
			neg edx
		@@:
		add ecx,edx
		.if ecx>256
			mov ecx,256
		.endif
		
		; ecx = max alpha
		;-----------------------/
		
		
		;-------------[ get alpha ]------------[
		mov ebx,256
		sub ebx,ecx
		mov eax,ecx
		; eax = Alpha
		; ebx = invAlpha
		;--------------------------------------/
		
		mov ecx,[edi]
		mov edx,ecx
		
		and ecx,0FF00FFh
		and edx,000FF00h
		imul ecx,ebx
		imul edx,ebx
		mov ebx,eax
		imul eax,TintRB
		imul ebx,TintG
		add eax,ecx
		add ebx,edx
		and eax,0FF00FF00h
		and ebx,000FF0000h
		add eax,ebx
		shr eax,8
		mov [edi],eax
		
		
		
		; out = (dcolor*(256-alpha) + color*alpha)/256 = 
		;  dcolor*256 - dcolor*alpha + color*alpha = dcolor*256 + alpha*(color-dcolor)
		
		
		
		
		add esi,4
		add edi,4
		dec wid2
		jnz _nextpix
		
		add esi,extraSrc
		add edi,extraDest
		dec hei
	jnz _nextline
	
		
	
	
_ret:	ret
sBltTintDirect endp




sDrawRectROP proc PUBLIC UseAll x,y,wid,hei,dwColor,dwROP
	local extraDest
	CHECKDRAWRECT
	COMPUTEBLTBITS	
	mov eax,dwColor
	mov edx,dwROP
	mov ebx,dwColor
	sub edi,4
	mov esi,sTarget_Data.linesize
	
	cmp edx,SD_COPY
	je _SD_COPY
	cmp edx,SD_XOR
	je _SD_XOR
	cmp edx,SD_ADD
	je _SD_ADD
	cmp edx,SD_SUB
	je _SD_SUB
	cmp edx,SD_OR
	je _SD_OR
	cmp edx,SD_AND
	je _SD_AND
	cmp edx,SD_SHR
	je _SD_SHR
	cmp edx,SD_MUL
	je _SD_MUL
	cmp edx,SD_ADDSAT
	je _SD_ADDSAT
	cmp edx,SD_SUBSAT
	je _SD_SUBSAT
	cmp edx,SD_SHRSAT
	je _SD_SHRSAT
	cmp edx,SD_SHLSAT
	je _SD_SHLSAT
	
	
	jmp _ret
	
	;------------[ COPY ]---------------[
	_SD_COPY:
		mov ecx,wid
		align 16
		@@:
			mov [edi+ecx*4],ebx
		dec ecx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _SD_COPY
	jmp _ret
	;-----------------------------------/
	
	
	;------------[ XOR ]---------------[
	_SD_XOR:
		mov ecx,wid
		align 16
		@@:
			xor [edi+ecx*4],ebx
		dec ecx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _SD_XOR
	jmp _ret
	;----------------------------------/
	
	;------------[ ADD ]---------------[
	_SD_ADD:
		mov ecx,wid
		@@:
			add [edi+ecx*4],ebx
		dec ecx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _SD_ADD
	jmp _ret
	;----------------------------------/
	
	;------------[ SUB ]---------------[
	_SD_SUB:
		mov ecx,wid
		@@:
			sub [edi+ecx*4],ebx
		dec ecx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _SD_SUB
	jmp _ret
	;----------------------------------/
	
	;------------[ OR  ]---------------[
	_SD_OR:
		mov ecx,wid
		@@:
			or [edi+ecx*4],ebx
		dec ecx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _SD_OR
	jmp _ret
	;----------------------------------/
	
	;------------[ AND ]---------------[
	_SD_AND:
		mov ecx,wid
		@@:
			and [edi+ecx*4],ebx
		dec ecx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _SD_AND
	jmp _ret
	;----------------------------------/
	
	;------------[ SHR ]---------------[
	_SD_SHR:
		mov ecx,ebx
		mov edx,wid
		@@:
			shr dword ptr [edi+ecx*4],cl
		dec edx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _SD_SHR
	jmp _ret
	;----------------------------------/
	
	;------------[ MUL ]---------------[
	_SD_MUL:
		mov ecx,wid
		@@:
			mov eax,[edi+ecx*4]
			mov edx,eax
			and eax,0FF00FFh
			and edx,000FF00h
			imul eax,ebx
			imul edx,ebx
			and eax,0FF00FF00h
			and edx,000FF0000h
			or eax,edx
			shr eax,8
			mov [edi+ecx*4],eax
		dec ecx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _SD_MUL
	jmp _ret
	;----------------------------------/
	
	;------------[ ADDSAT ]---------------[
	_SD_ADDSAT:
		movd mm1,dwColor
		_addsat_nl:
		mov ecx,wid
		align 16
		@@:
			movd mm0,[edi+ecx*4]
			paddusb mm0,mm1
			movd [edi+ecx*4],mm0
		dec ecx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _addsat_nl
	emms
	jmp _ret
	;-------------------------------------/
	
	;------------[ SUBSAT ]---------------[
	_SD_SUBSAT:
		movd mm1,dwColor
		_subsat_nl:
		mov ecx,wid
		align 16
		@@:
			movd mm0,[edi+ecx*4]
			psubusb mm0,mm1
			movd [edi+ecx*4],mm0
		dec ecx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _subsat_nl
	emms
	jmp _ret
	;-------------------------------------/
	;------------[ SHRSAT ]---------------[
	_SD_SHRSAT:
		mov ebx,07F7F7Fh
		_shrsat_nl:
		mov ecx,wid
		align 16
		@@:
			mov eax,[edi+ecx*4]
			shr eax,1
			and eax,ebx
			mov [edi+ecx*4],eax
		dec ecx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _shrsat_nl
	jmp _ret
	;-------------------------------------/
	;------------[ SHLSAT ]---------------[
	_SD_SHLSAT:
		mov ecx,wid
		align 16
		@@:
			movd mm0,[edi+ecx*4]
			paddusb mm0,mm0
			movd [edi+ecx*4],mm0
		dec ecx
		jnz @B
		
		add edi,esi
		dec hei
	jnz _SD_SHLSAT
	emms
	jmp _ret
	;-------------------------------------/
	
	
	
_ret:	ret
sDrawRectROP endp

;=====<< SdLoadFont >>===\
SFontStruct struct
	wid	dd ?
	hei	dd ?
	isMono	dd ?
	ChPoss	dw 96 dup (?)
	ChWids	db 96 dup (?)
	
	bits 	db 0 dup (?)
SFontStruct ends


sdLoadFont proc PUBLIC UseMost pFontData
	local pFont
	mov ecx,pFontData
	.if dword ptr[ecx]!='SDFT'
		xor eax,eax
		ret
	.endif
	mov pFont,malloc(dword ptr[ecx+8])
	invoke unpack,addr [ecx+12],pFont,dword ptr[ecx+4]
	
	mov eax,pFont
	ret
sdLoadFont endp
;=======/



;=====[[ tool: sTextOUTGetDrawnSize >>===\

sTextOUTGetDrawnSize proc PUBLIC uses ecx edx pText
	local maxwid,y
	local LineHei
	
	
	xor eax,eax
	mov ebx,pText
	mov maxwid,eax
	or ebx,ebx
	jz _ret
	
	mov ecx,SD_CurFont
	mov edx,[ecx].SFontStruct.hei
	mov LineHei,edx
	mov y,edx
	
	lea ecx,[ecx].SFontStruct.ChWids
	
	
	
 _again:
	movzx edx,byte ptr[ebx]
	inc ebx
	test edx,edx
	jz _ret
	.if edx>=32 && edx<128 ; drawable char
		sub edx,32
		movzx edx,byte ptr[ecx+edx]
		add eax,edx
		jmp _again
	.elseif edx==10
		.if eax>maxwid
			mov maxwid,eax
		.endif
		mov edx,LineHei
		add y,edx
		xor eax,eax
	.endif
	jmp _again
	
	
_ret:	
	.if maxwid>eax
		mov eax,maxwid
	.endif
	mov ebx,y
	ret
sTextOUTGetDrawnSize endp
;=======/
sTextPrintLine proc PRIVATE x,y,wid,hei,pText ; x,y,wid,hei are NOT random!
	
	ret
sTextPrintLine endp



sTextOut proc PUBLIC UseAll x,y,pText,dwColor
	local wid,hei
	local defaultX,LineDataSize,FontHei,FontWid
	local CharOffs,CharWid,IsMonochrome
	local esi2,edi2
	local dwColorG,dwColorRB
	
	cmp pText,0
	je _ret
	
	;-----[ try to clip early ]----------[
	mov eax,x
	mov edx,y
	add eax,SDDrawOffs.x
	add edx,SDDrawOffs.y
	cmp eax,SDBound.right
	jge _ret
	cmp edx,SDBound.bottom
	jge _ret
	mov x,eax
	mov defaultX,eax
	mov y,edx
	
	invoke sTextOUTGetDrawnSize,pText
	mov wid,eax
	mov hei,ebx
	add eax,x
	add ebx,y
	cmp eax,SDBound.left
	jle _ret
	cmp ebx,SDBound.top
	jle _ret
	;------------------------------------/
	
	;----[ preload data+registers ]-----[
	mov ebx,pText
	mov ecx,SD_CurFont
	mov edx,[ecx].SFontStruct.wid
	mov FontWid,edx
	mov edx,[ecx].SFontStruct.isMono
	mov IsMonochrome,edx
	mov edx,[ecx].SFontStruct.hei
	mov FontHei,edx
	imul edx,sTarget_Data.linesize
	mov LineDataSize,edx
	mov eax,sTarget_Data.wid
	imul eax,y
	mov edi,sTarget_Data.bits
	lea esi,[ecx].SFontStruct.bits
	lea edi,[edi+eax*4]	
	lea edx,[ecx].SFontStruct.ChWids
	lea ecx,[ecx].SFontStruct.ChPoss
	mov esi2,esi
	mov edi2,edi
	
	mov eax,dwColor
	and eax,000FF00h
	mov dwColorG,eax
	mov eax,dwColor
	and eax,0FF00FFh
	mov dwColorRB,eax
	;-----------------------------------/
	
	;------[ for each char ]-------------\
	_nextChar:
	
	movzx eax,byte ptr[ebx]
	inc ebx
	test eax,eax
	jz _ret
	.if al==10 ; on newline
		mov eax,FontHei
		add y,eax
		mov eax,defaultX
		mov x,eax
		mov eax,LineDataSize
		sub edi2,eax
		jmp _nextChar
	.endif
		
	.if eax>=32 && eax<128 ; drawable char
		sub eax,32
		pushi ebx,ecx,edx
		movzx ecx,word ptr[ecx+eax*2] ; ecx=char-offset
		movzx edx,byte ptr[edx+eax]   ; edx=char-width
		mov CharOffs,ecx
		mov CharWid,edx
		mov eax,x ; eax=left
		add x,edx			; increase target x with char width
		mov ebx,edx
		add ebx,eax; ebx= right
		mov ecx,y	; ecx=top
		mov edx,FontHei
		add edx,ecx	; edx=bottom	
		cmp eax,SDBound.right
		jge _charDone
		cmp ebx,SDBound.left
		jle _charDone
		cmp ecx,SDBound.bottom
		jge _charDone
		cmp edx,SDBound.top
		jle _charDone
		.if sdword ptr edx>SDBound.bottom
			mov edx,SDBound.bottom
		.endif
		.if sdword ptr ebx>SDBound.right
			mov ebx,SDBound.right
		.endif
		
		mov esi,esi2
		mov edi,edi2
		add esi,CharOffs
		lea edi,[edi+eax*4]
		
		
		.if IsMonochrome
			;-----------[ for each scanline ]-----------[
			_nextHScan:
			    .if sdword ptr ecx>=SDBound.top
				pushi eax,esi,edi
					;--[ for each h-pixel ]---[
					_nextpix:
						.if sdword ptr eax>=SDBound.left
							;------[ finally, fill the pixel ]------------[
							.if byte ptr[esi]
								m2m dword ptr[edi],dwColor
							.endif
							;---------------------------------------------/				
						.endif				
					inc eax
					add edi,4
					inc esi
					cmp eax,ebx
					jl _nextpix
					;-------------------------/
				poppi eax,esi,edi
			    .endif
			inc ecx
			add edi,sTarget_Data.linesize
			add esi,FontWid
			cmp ecx,edx
			jl _nextHScan
			;--------------------------------------------/	
		.else
			;-----------[ for each scanline ]-----------[
			_nextHScan2:
			    .if sdword ptr ecx>=SDBound.top
				pushi eax,ecx,edx,esi,edi
					;--[ for each h-pixel ]---[
					_nextpix2:
						.if sdword ptr eax>= sdword ptr SDBound.left
							;------[ finally, fill the pixel ]------------[
							pushi eax,ebx
							movzx eax,byte ptr[esi]
							mov ecx,[edi]
							
							;-----[ get alpha ]-----[
							mov ebx,256
							sub ebx,eax
							; eax = Alpha
							; ebx = invAlpha
							;-----------------------/
							
							
							mov edx,ecx
							
							and ecx,0FF00FFh
							and edx,000FF00h
							imul ecx,ebx
							imul edx,ebx
							mov ebx,eax
							imul eax,dwColorRB
							imul ebx,dwColorG
							add eax,ecx
							add ebx,edx
							and eax,0FF00FF00h
							and ebx,000FF0000h
							add eax,ebx
							shr eax,8
							mov [edi],eax
							
							poppi eax,ebx
							;---------------------------------------------/				
						.endif				
					inc eax
					add edi,4
					inc esi
					cmp eax,ebx
					jl _nextpix2
					;-------------------------/
				poppi eax,ecx,edx,esi,edi
			    .endif
			inc ecx
			add edi,sTarget_Data.linesize
			add esi,FontWid
			cmp ecx,edx
			jl _nextHScan2
			;--------------------------------------------/	
		.endif
				
		
		
		_charDone:
		;add x,1 ; move target x right, for char spacing
		poppi ebx,ecx,edx
	.endif
	jmp _nextChar
	;------------------------------------/
	
	
	
	
	
_ret:	ret
sTextOut endp



;=====[[ sdPrintDec >>===\
sdPrintDec proc PUBLIC UseAll x,y,Value,dwColor
	local digits[64]:byte
	local str1[64]:byte
	
	lea edi,str1
	mov eax,Value
	cmp eax,0
	jge @F
		neg eax
		mov byte ptr[edi],'-'
		inc edi
	@@:
	
	mov ecx,10
	xor ebx,ebx
	
	@@:
	xor edx,edx
	div ecx
	add dl,'0'
	mov digits[ebx],dl
	inc ebx
	or eax,eax
	jnz @B
	
	.while ebx
		dec ebx
		mov al,digits[ebx]
		mov [edi],al
		inc edi
	.endw
	mov byte ptr[edi],0
	
	
	invoke sTextOut,x,y,addr str1,dwColor
		
	ret
sdPrintDec endp
;=======/
sBltParam proc PUBLIC x,y,wid,hei,x2,y2,pSprite
	push pSourceSprite
	invoke sdSetSourceSprite,pSprite
	invoke sBlt,x,y,wid,hei,x2,y2
	call sdSetSourceSprite
	ret
sBltParam endp

sBltTransParam proc PUBLIC x,y,wid,hei,x2,y2,pSprite
	push pSourceSprite
	invoke sdSetSourceSprite,pSprite
	invoke sBltTrans,x,y,wid,hei,x2,y2
	call sdSetSourceSprite
	ret
sBltTransParam endp

sBltAlphaParam proc PUBLIC x,y,wid,hei,x2,y2,Alpha,pSprite
	push pSourceSprite
	invoke sdSetSourceSprite,pSprite
	invoke sBltAlpha,x,y,wid,hei,x2,y2,Alpha
	call sdSetSourceSprite
	ret
sBltAlphaParam endp

sBltTransAlphaParam proc PUBLIC x,y,wid,hei,x2,y2,Alpha,pSprite
	push pSourceSprite
	invoke sdSetSourceSprite,pSprite
	invoke sBltTransAlpha,x,y,wid,hei,x2,y2,Alpha
	call sdSetSourceSprite
	ret
sBltTransAlphaParam endp

sBltAddParam proc PUBLIC x,y,wid,hei,x2,y2,pSprite
	push pSourceSprite
	invoke sdSetSourceSprite,pSprite
	invoke sBltAdd,x,y,wid,hei,x2,y2
	call sdSetSourceSprite
	ret
sBltAddParam endp

sBltAddFadeParam proc PUBLIC x,y,wid,hei,x2,y2,Fader,pSprite
	push pSourceSprite
	invoke sdSetSourceSprite,pSprite
	invoke sBltAddFade,x,y,wid,hei,x2,y2,Fader
	call sdSetSourceSprite
	ret
sBltAddFadeParam endp


sBltTintParam proc PUBLIC x,y,wid,hei,x2,y2,dwColor,pSprite
	push pSourceSprite
	invoke sdSetSourceSprite,pSprite
	invoke sBltTint,x,y,wid,hei,x2,y2,dwColor
	call sdSetSourceSprite
	ret
sBltTintParam endp


InitSDraw proc PUBLIC UseAll wid,hei
	
	local DesktopDC
	local bits
	.if !wid
		invoke GetSystemMetrics,SM_CXSCREEN
		mov wid,eax
	.endif
	.if !hei
		invoke GetSystemMetrics,SM_CYSCREEN
		mov hei,eax
	.endif
	m2m ScreenSize.x,wid
	m2m ScreenSize.y,hei
	
	
	;---------[ make backDC ]----------[
	invoke GetDC,0
	mov DesktopDC,eax
	invoke CreateCompatibleDC,eax
	mov backDC,eax
	invoke ReleaseDC,0,DesktopDC
	;----------------------------------/
	
	invoke CreateDIBsprite,wid,hei
	mov SD_BackSprite,eax
	invoke SelectObject,backDC,[eax].sSprite.hBitmap
	mov backDC_PrevHBmp,eax
	
	
	ret
InitSDraw endp

ResizeSDrawArea proc PUBLIC UseAll wid,hei
	;-------[ check params ]---------------------[
	.if !wid
		invoke GetSystemMetrics,SM_CXSCREEN
		mov wid,eax
	.endif
	.if !hei
		invoke GetSystemMetrics,SM_CYSCREEN
		mov hei,eax
	.endif
	;--------------------------------------------/
	
	;-----[ exit if no actual change ]---------[
	mov eax,wid
	mov edx,hei
	.if eax==ScreenSize.x && edx==ScreenSize.y
		ret
	.endif
	;------------------------------------------/
	
	m2m ScreenSize.x,wid
	m2m ScreenSize.y,hei
	
	;-------[ replace the DIBsprite ]-----------[
	invoke SelectObject,backDC,backDC_PrevHBmp
	mov eax,SD_BackSprite
	invoke DeleteObject,[eax].sSprite.hBitmap
	free SD_BackSprite
	invoke CreateDIBsprite,wid,hei
	mov SD_BackSprite,eax
	invoke SelectObject,backDC,[eax].sSprite.hBitmap
	mov backDC_PrevHBmp,eax
	invoke sdSetTargetSprite,0
	;-------------------------------------------/
	
	
	
	ret
ResizeSDrawArea endp


FreeSDraw proc PUBLIC UseAll
	invoke sdDeleteAllSprites ; unnecessary
	
	;--------[ free the main DIB ]--------------------[
	invoke SelectObject,backDC,backDC_PrevHBmp
	mov eax,SD_BackSprite
	invoke DeleteObject,[eax].sSprite.hBitmap
	free SD_BackSprite
	invoke DeleteObject,backDC
	mov SD_BackSprite,0
	mov backDC,0
	;-------------------------------------------------/
	
	
	ifndef HEAP1
		invoke HeapDestroy,HEAP2
		mov HEAP2,0
	endif
	
	ret
FreeSDraw endp







sdGetCtlVariable proc PUBLIC VariableID
	mov eax,VariableID
	.if eax==SDVAR_ID_SD_TransparentColor
		mov eax,SD_TransparentColor
		ret
	.elseif eax==SDVAR_ID_SD_CurFont
		mov eax,SD_CurFont
		ret
	.elseif eax==SDVAR_ID_SDBound_ptr
		lea eax,SDBound
		ret
	.elseif eax==SDVAR_ID_SDDrawOffs_ptr
		lea eax,SDDrawOffs
		ret
	.elseif eax==SDVAR_ID_sTarget_Data
		lea eax,sTarget_Data
		ret
	.elseif eax==SDVAR_ID_sSource_Data
		lea eax,sSource_Data
		ret
	.elseif eax==SDVAR_ID_SDBackDC
		mov eax,SDBackDC
		ret
	.elseif eax==SDVAR_ID_SDhDC
		mov eax,SDhDC
		ret
	.endif
	xor eax,eax
	ret
sdGetCtlVariable endp


sdSetCtlVariable proc PUBLIC VariableID,Value
	.if VariableID==SDVAR_ID_SD_TransparentColor
		m2m SD_TransparentColor,Value
	.elseif VariableID==SDVAR_ID_SD_CurFont
		m2m SD_CurFont,Value
	.endif
	ret
sdSetCtlVariable endp	



.data?
	sdSDOS_Prev_DOx dd ?
	sdSDOS_Prev_DOy dd ?
	sdSDOS_Prev_DBl dd ?
	sdSDOS_Prev_DBr dd ?
	sdSDOS_Prev_DBt dd ?
	sdSDOS_Prev_DBb dd ?
	sdSDOS_Prev_OBl dd ?
	sdSDOS_Prev_OBr dd ?
	sdSDOS_Prev_OBt dd ?
	sdSDOS_Prev_OBb dd ?
	sdSDOS_Prev_PSS dd ?
	sdSDOS_Prev_PTS dd ?
	
.code
	
sdStartDrawingOnSprite proc PUBLIC UseAll TargetSprite
	;-------[ save current state ]-----[
	push SDDrawOffs.x
	push SDDrawOffs.y
	push SDBound.left
	push SDBound.right
	push SDBound.top
	push SDBound.bottom
	push SDOriginalBound.left
	push SDOriginalBound.right
	push SDOriginalBound.top
	push SDOriginalBound.bottom
	push pSourceSprite
	push pTargetSprite
	
	pop sdSDOS_Prev_PTS
	pop sdSDOS_Prev_PSS 
	pop sdSDOS_Prev_OBb 
	pop sdSDOS_Prev_OBt 
	pop sdSDOS_Prev_OBr 
	pop sdSDOS_Prev_OBl 
	pop sdSDOS_Prev_DBb 
	pop sdSDOS_Prev_DBt 
	pop sdSDOS_Prev_DBr 
	pop sdSDOS_Prev_DBl 
	pop sdSDOS_Prev_DOy
	pop sdSDOS_Prev_DOx
	;----------------------------------/
	
	
	
	mov ecx,TargetSprite
	xor eax,eax
	
	mov SDDrawOffs.x,eax
	mov SDDrawOffs.y,eax
	mov SDBound.left,eax
	mov SDBound.top,eax
	m2m SDBound.right,[ecx].sSprite.wid
	m2m SDBound.bottom,[ecx].sSprite.hei
	
	m2m SDOriginalBound.left,  SDBound.left
	m2m SDOriginalBound.top,   SDBound.top
	m2m SDOriginalBound.right, SDBound.right
	m2m SDOriginalBound.bottom,SDBound.bottom
	
	invoke sdSetTargetSprite,TargetSprite
	
	ret
sdStartDrawingOnSprite endp	


sdEndDrawingOnSprite proc PUBLIC
	;-------[ load previous state ]-----[
	push sdSDOS_Prev_PTS
	push sdSDOS_Prev_PSS 
	push sdSDOS_Prev_OBb 
	push sdSDOS_Prev_OBt 
	push sdSDOS_Prev_OBr 
	push sdSDOS_Prev_OBl 
	push sdSDOS_Prev_DBb 
	push sdSDOS_Prev_DBt 
	push sdSDOS_Prev_DBr 
	push sdSDOS_Prev_DBl 
	push sdSDOS_Prev_DOy
	push sdSDOS_Prev_DOx
	
	pop SDDrawOffs.x
	pop SDDrawOffs.y
	pop SDBound.left
	pop SDBound.right
	pop SDBound.top
	pop SDBound.bottom
	pop SDOriginalBound.left
	pop SDOriginalBound.right
	pop SDOriginalBound.top
	pop SDOriginalBound.bottom
	pop pSourceSprite
	pop pTargetSprite
	;----------------------------------/
	invoke sdSetSourceSprite,pSourceSprite
	invoke sdSetTargetSprite,pTargetSprite
	ret
sdEndDrawingOnSprite endp

	


sdStart proc PUBLIC UseMost hWnd
	m2m SDhWnd,hWnd
	invoke GetDC,hWnd
	mov SDhDC,eax
	invoke GetClipBox,SDhDC,addr SDBound
	.if eax==NULLREGION
		invoke ReleaseDC,hWnd,SDhDC
		mov SDhWnd,0
		mov SDhDC,0
		xor eax,eax
		ret
	.endif
	
	m2m SDOriginalBound.left,  SDBound.left
	m2m SDOriginalBound.top,   SDBound.top
	m2m SDOriginalBound.right, SDBound.right
	m2m SDOriginalBound.bottom,SDBound.bottom
	
	
	mov SDDrawOffs.x,0
	mov SDDrawOffs.y,0
	
	invoke sdSetSourceSprite,0
	invoke sdSetTargetSprite,0
	
	mov pClipStack,offset ClipStackData
	
	;---[ return 1, clear zero flag ]---[
	xor eax,eax
	inc eax
	ret
	;-----------------------------------/
sdStart endp

sdEnd proc PUBLIC UseAll
	mov eax,SDOriginalBound.right
	mov edx,SDOriginalBound.bottom
	sub eax,SDOriginalBound.left
	sub edx,SDOriginalBound.top
	
	invoke BitBlt,SDhDC,SDOriginalBound.left,SDOriginalBound.top,eax,edx,\
		backDC,SDOriginalBound.left,SDOriginalBound.top,SRCCOPY
	invoke ReleaseDC,SDhWnd,SDhDC
	mov SDhWnd,0
	mov SDhDC,0
	ret
sdEnd endp


sdStartEx proc PUBLIC UseAll hWnd,dwType
	m2m SDhWnd,hWnd
	invoke GetDC,hWnd
	mov SDhDC,eax
	;-------------[ get major clipping box ]-------------------------------------[
	.if dwType==SDSTARTEX_ONUPDATEREGION
		;---[ if on update-region ]-------------\
		invoke GetUpdateRect,hWnd,addr SDBound,0
		.if !eax
		_sdStartExFailed:
			invoke ReleaseDC,hWnd,SDhDC
			mov SDhWnd,0
			mov SDhDC,0
			xor eax,eax
			ret
		.endif	
		;---------------------------------------/	
	.else ;----[ if on draw-region, or custom-region ]------------\
		invoke GetClipBox,SDhDC,addr SDBound	
		cmp eax,NULLREGION
		je _sdStartExFailed
		;-----------------------------------------------------/
	.endif
	;-----------------------------------------------------------------------------/
	
	;-------[ intersect if a custom rectangle is specified ]----------------[
	.if dwType!=SDSTARTEX_ONDRAWREGION && dwType!=SDSTARTEX_ONUPDATEREGION
		mov edx,dwType
		;---[ clip horizontal ]--------[
		mov eax,[edx].RECT.left
		mov ecx,[edx].RECT.right
		cmp eax,SDBound.left
		jge @F
			mov eax,SDBound.left
		@@:
		cmp ecx,SDBound.right
		jle @F
			mov ecx,SDBound.right
		@@:
		cmp eax,ecx
		jge _sdStartExFailed
		mov SDBound.left,eax
		mov SDBound.right,ecx
		;------------------------------/
		;---[ clip vertical ]----------[
		mov eax,[edx].RECT.top
		mov ecx,[edx].RECT.bottom
		cmp eax,SDBound.top
		jge @F
			mov eax,SDBound.top
		@@:
		cmp ecx,SDBound.bottom
		jle @F
			mov ecx,SDBound.bottom
		@@:
		cmp eax,ecx
		jge _sdStartExFailed
		mov SDBound.top,eax
		mov SDBound.bottom,ecx
		;------------------------------/
			
	.endif
	;-----------------------------------------------------------------------/
	
	
	m2m SDOriginalBound.left,  SDBound.left
	m2m SDOriginalBound.top,   SDBound.top
	m2m SDOriginalBound.right, SDBound.right
	m2m SDOriginalBound.bottom,SDBound.bottom
	
	
	mov SDDrawOffs.x,0
	mov SDDrawOffs.y,0
	
	invoke sdSetSourceSprite,0
	invoke sdSetTargetSprite,0
	
	mov pClipStack,offset ClipStackData
	
	;---[ return 1, clear zero flag ]---[
	xor eax,eax
	inc eax
	ret
	;-----------------------------------/
	ret
sdStartEx endp

sdEndEx proc PUBLIC UseAll bDoUpdate
	.if bDoUpdate
		mov eax,SDOriginalBound.right
		mov edx,SDOriginalBound.bottom
		sub eax,SDOriginalBound.left
		sub edx,SDOriginalBound.top
		invoke BitBlt,SDhDC,SDOriginalBound.left,SDOriginalBound.top,eax,edx,\
			backDC,SDOriginalBound.left,SDOriginalBound.top,SRCCOPY
	.endif
	
	invoke ReleaseDC,SDhWnd,SDhDC
	mov SDhWnd,0
	mov SDhDC,0
	ret
sdEndEx endp


sdForceUpdate proc PUBLIC UseAll
	mov eax,SDBound.right
	mov edx,SDBound.bottom
	sub eax,SDBound.left
	sub edx,SDBound.top
	
	invoke BitBlt,SDhDC,SDBound.left,SDBound.top,eax,edx,backDC,SDBound.left,SDBound.top,SRCCOPY
	ret
sdForceUpdate endp

sdFetchBackground proc PUBLIC UseAll
	mov eax,SDOriginalBound.right
	mov edx,SDOriginalBound.bottom
	sub eax,SDOriginalBound.left
	sub edx,SDOriginalBound.top
	
	invoke BitBlt,backDC,SDOriginalBound.left,SDOriginalBound.top,eax,edx,\
		SDhDC,SDOriginalBound.left,SDOriginalBound.top,SRCCOPY
	ret
sdFetchBackground endp


if COMPILE_AS_DLL

	LibMain proc PUBLIC hInstDLL,reason, unused
		mov eax,1
		ret
	LibMain Endp
	
	sdSetCurFont proc PUBLIC pFont
		m2m SD_CurFont,pFont
		ret
	sdSetCurFont endp
	
	
	
	
	@CatStr(<en>,<dif>) ; trick masm
	@CatStr(<en>,<d LibMain>) ; trick masm
endif


if COMPILE_AS_EXE eq 0
	@CatStr(<en>,<dif>) ; trick masm
	@CatStr(<en>,<d  >) ; trick masm
endif





includelib \masm32\lib\ole32.lib
includelib \masm32\lib\oleaut32.lib




include Font1.inc
MakeOneWindow proc wid,hei,pFunc,pTitle
	local wc:WNDCLASSEX
	local rect:RECT
	local hInst
	Clear wc
	mov wc.cbSize,sizeof  wc
	m2m wc.lpfnWndProc,pFunc
	mov wc.hCursor,$invoke(LoadCursor,0,IDC_ARROW)
	mov wc.hInstance,$invoke(GetModuleHandle,0)
	mov hInst,eax
	mov wc.hIcon,$invoke (LoadIcon,eax,1)
	mov wc.lpszClassName,T("OneWindowCls")
	invoke RegisterClassEx,addr wc
	;-------------------------------------------/
	;-----[ adjust window size ]---------\
	mov rect.left,0
	mov rect.top,0
	m2m rect.right,wid
	m2m rect.bottom,hei
	invoke AdjustWindowRect,addr rect,WS_POPUP or WS_CAPTION or WS_VISIBLE or WS_SYSMENU,0
	mov eax,rect.right
	sub eax,rect.left
	mov ecx,rect.bottom
	sub ecx,rect.top
	;------------------------------------/
	
	invoke CreateWindowEx,0,wc.lpszClassName,pTitle,WS_POPUP or WS_CAPTION or WS_VISIBLE or WS_SYSMENU,50,50,eax,ecx,0,0,hInst,0
	ret
MakeOneWindow endp



;
;
; To test this file, remove the "end" above, and in sDraw.tix  remove the "!"  from "!sDraw"
;
;

.data
	spr1 dd ?
	spr2 dd ?
	dude dd ?
	ball dd ?
	txt1 dd ?
	jpg1 dd ?
	imgCable dd ?
	round1 dd ?
	hwnd1 dd ?
	
	font1 dd ?
.code
	
	
includelib Ball_tga.lib
externdef Ball_tga:DWORD
	

Cable struct
	first	POINT <>
	p1	POINT <>
	p3	POINT <>
	last 	POINT <>
	inert1	POINT <>
	inert3	POINT <>
	IsResting	dd ?
	dwColor	dd  151515h
Cable ends


AnimateCable proc UseAll pCable
	local p1x,p3x,p1y,p3y
	local I1:POINT,I3:POINT ; intertias, in real4
	local TM:POINT ; in int
	mov ecx,pCable
	assume ecx:ptr Cable
	.if !ecx || [ecx].IsResting
		ret
	.endif
	
	
	;----[ compute TM ]--------------\
	mov eax,[ecx].first.x
	add eax,[ecx].last.x
	sar eax,1
	mov TM.x,eax
	
	mov eax,[ecx].first.y
	mov edx,[ecx].last.y
	.if sdword ptr eax<edx
		mov eax,edx
	.endif
	add eax,50
	mov edx,[ecx].first.x
	sub edx,[ecx].last.x
	.if SIGN?
		neg edx
	.endif
	sar edx,2
	add eax,edx
	
	
	
	mov TM.y,eax
	;--------------------------------/
	
	;-----[ compute p1x,p3x ]-------[
	; p1x = avg(tmx,firstx
	mov ebx,TM.x
	mov edx,ebx
	add ebx,[ecx].first.x
	add edx,[ecx].last.x
	sar ebx,1
	sar edx,1
	mov p1x,ebx
	mov p3x,edx	
	;-------------------------------/
	;------[ compute p1y,p3y ]--------[
	mov ebx,TM.y
	lea ebx,[ebx+ebx*2]
	mov edx,ebx
	add ebx,[ecx].first.y
	add edx,[ecx].last.y
	sar ebx,1
	sar edx,1
	mov p1y,ebx
	mov p3y,edx
	m2m p1y,TM.y
	m2m p3y,TM.y
	;---------------------------------/
	
	
.data
	ccvar1 real4 0.2 ; speed
	ccvar2 real4 0.7 ; elasticity
.code
	
	@@INERTCAB macro _PTX,_PT,_INER
		fild _PTX
		fisub [ecx]._PT
		fmul ccvar1
		fadd [ecx]._INER
		fild [ecx]._PT
		fadd ST,ST(1)
		fistp [ecx]._PT
		fmul ccvar2
		fstp [ecx]._INER
		
		;mov eax,_PTX
		;sub eax,[ecx]._PT
		;sar eax,2
		;add eax,[ecx]._INER
		;add [ecx]._PT,eax
		;sar eax,1
		;mov [ecx]._INER,eax
	endm
	
	
	
	;---[ compute I1, anim P1 ]-----\
	@@INERTCAB p1x,p1.x,inert1.x
	@@INERTCAB p1y,p1.y,inert1.y
	;-------------------------------/
	
	;---[ compute I3, anim P3 ]-----\
	@@INERTCAB p3x,p3.x,inert3.x
	@@INERTCAB p3y,p3.y,inert3.y
	;-------------------------------/
	
	mov esi,7FFFFFFFh
	movf edi,0.1
	mov eax,[ecx].inert1.x
	mov ebx,[ecx].inert1.y
	mov edx,[ecx].inert3.x
	mov ecx,[ecx].inert3.y
	and eax,esi
	and ebx,esi
	and ecx,esi
	and edx,esi
	
	.if eax<edi && ebx<edi && ecx<edi && edx<edi
		mov ecx,pCable
		mov [ecx].IsResting,1
	.endif
	
	
	
	
	assume ecx:nothing
	ret
AnimateCable endp



Shader1 proc x,y,dwColor
	invoke sDrawRectROP,x,y,5,5,151515h,SD_SUBSAT
	ret
Shader1 endp


Shader3 proc uses ecx x,y,dwColor
.data
	SH3WR dd 0
	SH3RD dd 0
	SH3HX dd 8 dup (?)
	SH3HY dd 8 dup (?)
.code
	invoke sBltTint,x,y,5,5,0,0,dwColor
	mov ecx,SH3WR
	and ecx,7
	m2m SH3HX[ecx*4],x
	m2m SH3HY[ecx*4],y
	inc SH3WR
	.if SH3WR>4
		mov ecx,SH3RD
		and ecx,7		
		invoke sBltAdd,SH3HX[ecx*4],SH3HY[ecx*4],5,5,12,0
		inc SH3RD
	.endif	
	
	ret
Shader3 endp
Shader3_init proc
	mov SH3WR,0
	mov SH3RD,0
	ret
Shader3_init endp
Shader3_finish proc
	mov eax,SH3RD
	mov ecx,eax
	.while eax!=SH3WR
		and ecx,7
		invoke sBltAdd,SH3HX[ecx*4],SH3HY[ecx*4],5,5,6,0
		inc eax
		inc ecx
	.endw
	
	ret
Shader3_finish endp

DrawCable proc pCable,IsSelected
	;----[ SHADOW ]-------------------------------------[
	mov ecx,pCable
	
	
	
	assume ecx:ptr Cable
	mov eax,10
	add [ecx].first.x,2
	add [ecx].first.y,2
	add [ecx].p1.x,eax
	add [ecx].p1.y,eax
	add [ecx].p3.x,eax
	add [ecx].p3.y,eax
	.if IsSelected
		add [ecx].last.x,eax
		add [ecx].last.y,eax
	.endif
	
	invoke sDrawBSplineShade,ecx,20,0,Shader1,5
	sub [ecx].first.x,2
	sub [ecx].first.y,2
	sub [ecx].p1.x,eax
	sub [ecx].p1.y,eax
	sub [ecx].p3.x,eax
	sub [ecx].p3.y,eax
	.if IsSelected
		sub [ecx].last.x,eax
		sub [ecx].last.y,eax
	.endif
	;---------------------------------------------------/
	
	;------[ CABLE ]----------------------------------\
	invoke sdSetSourceSprite,imgCable
	invoke Shader3_init
	mov ecx,pCable
	invoke sDrawBSplineShade,pCable,20,[ecx].dwColor,Shader3,5
	invoke Shader3_finish
	
	;-------------------------------------------------/
	;mov ecx,pCable
	;invoke sBltTint,[ecx].p1.x,[ecx].p1.y,5,5,0,0,[ecx].dwColor
	;invoke sBltTint,[ecx].p3.x,[ecx].p3.y,5,5,0,0,[ecx].dwColor
	;invoke sDrawRectROP,[ecx].p1.x,[ecx].p1.y,8,8,303030h,SD_ADDSAT
	;invoke sDrawRectROP,[ecx].p3.x,[ecx].p3.y,8,8,303030h,SD_ADDSAT
	
	
	
	assume ecx:nothing
	ret
DrawCable endp


DistanceFromLineToPoint proc uses ebx ecx edx mousex,mousey,X0,Y0,X1,Y1 
	;dist = abs( ;(Y0-Y1)*mousex + (X1-X0)*mousey + (X0*Y1) - (X1*Y0) ;) 
	mov eax,X0
	mov ebx,X1
	mov ecx,Y0
	mov edx,Y1
	.if sdword ptr eax>ebx
		xchg eax,ebx
	.endif
	.if sdword ptr ecx>edx
		xchg ecx,edx
	.endif
	sub eax,4
	add ebx,4
	sub ecx,4
	add edx,4
	cmp mousex,eax
	jl _ret
	cmp mousex,ebx
	jg _ret
	cmp mousey,ecx
	jl _ret
	cmp mousey,edx
	jg _ret
	
	
	
	mov eax,Y0
	sub eax,Y1 
	imul eax,mousex 
	mov ebx,X1 
	sub ebx,X0 
	imul ebx,mousey 
	mov ecx,X0 
	imul ecx,Y1 
	mov edx,X1 
	imul edx,Y0 
	add eax,ebx 
	add eax,ecx 
	sub eax,edx 
	imul eax,eax
	
	mov ebx,X1
	sub ebx,X0
	mov ecx,Y1
	sub ecx,Y0
	imul ebx,ebx
	imul ecx,ecx
	add ebx,ecx
	xor edx,edx
	inc ebx
	div ebx
	ret
	
	
_ret:	mov eax,7FFFFFFFh
	ret
DistanceFromLineToPoint endp

DrawSpline proc UseAll
	local pt:POINT
	
	invoke GetCursorPos,addr pt
	invoke ScreenToClient,hwnd1,addr pt
.data
	cab1 Cable <<400,130>,<0,0>,<0,0>,<200,0>,<0,0>,<0,0>,0,00800000h>
	cab2 Cable <<400,0>,<0,0>,<0,0>,<10,50>,<0,0>,<0,0>,0,0>
	cab3 Cable <<0,100>,<0,0>,<0,0>,<0,0>,<0,0>,<0,0>,0,804000h>
	cab4 Cable <<0,10>,<0,0>,<0,0>,<0,0>,<0,0>,<0,0>,0,100>
	cab5 Cable <<0,140>,<0,0>,<0,0>,<400,0>,<0,0>,<0,0>,0,100>
	cab6 Cable <<0,160>,<0,0>,<0,0>,<400,0>,<0,0>,<0,0>,0,100>
	cab7 Cable <<0,100>,<0,0>,<0,0>,<400,0>,<0,0>,<0,0>,0,100>
	cab8 Cable <<0,170>,<0,0>,<0,0>,<400,100>,<0,0>,<0,0>,0,100>
.code
	
	mov eax,pt.x
	mov ecx,pt.y
	
	mov cab3.last.x,eax
	mov cab3.last.y,ecx
	mov cab3.IsResting,0
	
	
	invoke AnimateCable,addr cab1
	invoke AnimateCable,addr cab2
	invoke AnimateCable,addr cab3
	invoke AnimateCable,addr cab4
	invoke AnimateCable,addr cab5
	invoke AnimateCable,addr cab6
	invoke AnimateCable,addr cab7
	invoke AnimateCable,addr cab8
	invoke DrawCable,addr cab1,0
	invoke DrawCable,addr cab2,0
	invoke DrawCable,addr cab4,0
	invoke DrawCable,addr cab5,0
	invoke DrawCable,addr cab6,0
	invoke DrawCable,addr cab7,0
	invoke DrawCable,addr cab8,0
	
	
	invoke DrawCable,addr cab3,1
	
.data
	Line1 POINT <200,200>
	Line2 POINT <100,200>
.code
	
	;trace "%d:%d",pt.x,pt.y
	invoke DistanceFromLineToPoint,pt.x,pt.y,Line1.x,Line1.y,Line2.x,Line2.y
	
	mov edx,255
	.if eax<=16
		shl edx,16
	.endif
	invoke sDrawLine,Line1.x,Line1.y,Line2.x,Line2.y,edx
	ret
DrawSpline endp
	
	
TestDraw proc hWnd
	local sdl:SDLOCKEDRECT
	local pt:POINT
	
	invoke GetCursorPos,addr pt
	invoke ScreenToClient,hwnd1,addr pt
	
	
	invoke sdStart,hWnd
	jz _ret
	
	invoke sdSetSourceSprite,spr2
	invoke sBlt,0,0,400,300,0,0
	
	
	
	
	invoke sdSetSourceSprite,spr1
	invoke sBltAlpha,50,80,100,100,0,0,80
	
	invoke sdEnterClip,40,40,100,30
	invoke sDrawRectROP,0,0,100,30,RGB(30,0,0),SD_ADDSAT
	invoke sTextOut,0,0,T("An especially long text?",13,10,"Should show correctly"),-1
	invoke sdLeaveClip
	
	invoke GetTickCount
	shr eax,3
	and eax,511
	.if eax>256
		sub eax,512
		neg eax
	.endif	
	mov edx,eax
	shr edx,2
	add eax,100
	invoke sBltAddFade,eax,28,24,24,100,0,eax
	
	invoke sdSetSourceSprite,dude
	invoke sBlt,pt.x,pt.y,46,57,0,0
	;invoke sBltTint,220,60,125,57,50,0,-1
	
	invoke sdSetSourceSprite,txt1
	invoke sBltTint,220,200,100,50,0,0,-1
	invoke sDrawRectROP,100,100,400,300,65 shl 16,SD_ADDSAT
	;invoke sdSetSourceSprite,ball
	;invoke sBlt,0,10,100,100,0,0
	;invoke sBltAlpha,-90,100,100,100,0,0,200
	
	invoke DrawSpline
	
		
		
	
	
	
	
	invoke sdEnd
_ret:	ret
TestDraw endp



WinPric proc UseMost hWnd,msg,w,l
	.if msg==WM_CLOSE
		invoke PostQuitMessage,0
	.elseif msg==WM_PAINT
		invoke TestDraw,hWnd
		invoke ValidateRect,hWnd,0
	.elseif msg==WM_TIMER
		invoke TestDraw,hWnd
	.elseif msg==WM_KEYDOWN && w==VK_ESCAPE
		invoke PostQuitMessage,0
	.else
		invoke DefWindowProc,hWnd,msg,w,l
		ret
	.endif
	xor eax,eax
	ret
WinPric endp

.data
	ilkoz dd 255
.code
	
main proc
	local msg:MSG
	local loop1,atom1
	
	invoke CoInitialize,0
	
	invoke InitSDraw,0,0
	
	
	
	
	invoke sdSpriteFromBitmapFile,T("main.bmp")
	mov spr1,eax
	
	invoke sdSpriteFromBitmapFile,T("back.bmp")
	mov spr2,eax
	
	invoke sdSpriteFromBitmapFile,T("dude.bmp")
	mov dude,eax
	
	invoke sdSpriteFromBitmapFile,T("txt1.bmp")
	mov txt1,eax
	
	invoke sdSpriteFromJPGFile,T("jpg1.jpg")
	mov jpg1,eax
	
	invoke sdSpriteFromILBFile,T("cable1.ilb")
	mov imgCable,eax
	
	
	
	invoke sdSpriteFromILB,addr Ball_tga
	mov ball,eax
	
	invoke sdSpritePreprocess_AlphaFromColor,dude,RGB(255,0,255)
	invoke sdSpritePreprocess_AlphaFromColor,txt1,0
	invoke sdSpritePreprocess_PremultiplyAlpha,dude
	;invoke sdSpritePreprocess_PremultiplyAlpha,ball
	invoke sdSpriteFromILBFile,T("round1.ilb")
	mov round1,eax
	invoke sdSpritePreprocess_PremultiplyAlpha,eax
	
	invoke sdLoadFont,addr WildWordsBold_fntdata
	mov font1,eax
	m2m SD_CurFont,font1
	;print [eax].SFontStruct.isMono
	
	
	invoke MakeOneWindow,400,300,WinPric,T("hello sDraw")
	mov hwnd1,eax
	
	
	
	invoke SetTimer,hwnd1,1,20,0
	MessageLoop
	
	invoke sdDeleteSprite,dude
	
	invoke CoUninitialize
	
	ret
main endp


start:
	print "hello1"
	invoke main
	print "hello"
	invoke ExitProcess,0

end start
