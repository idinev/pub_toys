;----------[ normal includes ... ]---------\
.686
.model flat,stdcall
.mmx
option casemap :none
option proc:private
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\gdi32.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib
include ..\sDraw.inc
includelib ..\sDraw.lib
;------------------------------------------/


WND_STYLE equ WS_POPUP or WS_CAPTION or WS_VISIBLE or WS_SYSMENU

.data
	wc WNDCLASSEX <>
	wndClass db "WindowClass1",0
	wndTitle db "sDraw Example",0
	lpszPoint db "point.bmp",0
	lpszKnob4 db "KNOB4.ilb",0
	
	
	CurTime  	dd 0
	pPointBmp	dd ?
	
	knob4 		dd 0
	
	IsFirstRun dd 1
.code





TestDraw proc hWnd
	local x,y,z
	local NumStars
	
	
	invoke sdStart,hWnd ; start drawing on window
	jz _ret ; window is not visible
	
	.if IsFirstRun
		invoke sDrawRect,0,0,2000,2000,0CCCCCCh
		mov IsFirstRun,0
	.endif
	
	invoke GetTickCount
	shr eax,5
	xor edx,edx
	mov ecx,61*2-1
	div ecx
	sub edx,61
	jns @F
		neg edx
	@@:
	mov eax,edx
	and eax,15
	shr edx,4
	imul eax,29
	imul edx,29
	invoke sBltParam,100,100,29,29,eax,edx,knob4
	;invoke sDrawRect,100,200,100,100,eax
	
	jmp done
	invoke sDrawRectAlpha,0,0,1400,900,0,85
	
	;----------------[ draw starfield ]----------------[
	invoke sdSetSourceSprite,pPointBmp
	mov eax,CurTime
	add eax,3215
	mov z,eax
	mov ecx,351345 ; Seed1
	mov NumStars,1000
	NextStar:
		;----[ compute 3D x:y ]-----[
		imul ecx,214013
		add ecx,2531011
		mov eax,ecx
		imul ecx,314013
		add ecx,1531011
		mov ebx,ecx
		sar eax,16
		sar ebx,16
		;---------------------------/
		;---[ compute 3D z ]-----[
		add z,3243561
		and z,1023
		inc z
		;------------------------/
		;---[ map 3D -> 2D ]----[
		cdq
		idiv z
		add eax,200
		mov x,eax
		mov eax,ebx
		cdq
		idiv z
		add eax,150
		mov y,eax
		;-----------------------/
		;----[ compute lightness ]------[
		mov edx,1024
		sub edx,z
		shr edx,2
		;mov dh,dl
		;shl edx,8
		;mov dl,dh
		;-------------------------------/
		;invoke sdSetPixel,x,y,edx
		invoke sBltAddFade,x,y,16,16,0,0,50;edx
	
	dec NumStars
	jnz NextStar
	
	sub CurTime,-10
	and CurTime,1023
	;--------------------------------------------------/
	done:
	
	invoke sdEnd ; end drawing on window
_ret:	ret
TestDraw endp





;----------[ creates an arbitrary window ]---------------------[
MakeOneWindow proc wid,hei,pFunc,pTitle,dwStyle1
	local rect:RECT
	local hInst
	
	mov wc.cbSize,sizeof  wc
	
	push pFunc
	pop wc.lpfnWndProc
	invoke LoadCursor,0,IDC_ARROW
	mov wc.hCursor,eax
	invoke GetModuleHandle,0
	mov wc.hInstance,eax
	mov hInst,eax
	mov wc.lpszClassName,offset wndClass
	invoke RegisterClassEx,addr wc
	;-------------------------------------------/
	;-----[ adjust window size ]---------\
	mov rect.left,0
	mov rect.top,0
	push wid
	pop rect.right
	push hei
	pop rect.bottom
	invoke AdjustWindowRect,addr rect,dwStyle1,0
	mov eax,rect.right
	sub eax,rect.left
	mov ecx,rect.bottom
	sub ecx,rect.top
	;------------------------------------/
	
	invoke CreateWindowEx,0,wc.lpszClassName,pTitle,dwStyle1,50,50,eax,ecx,0,0,hInst,0
	ret
MakeOneWindow endp
;--------------------------------------------------------------/












;--------------[ main window's procedure ]------------------------[
WinProc proc hWnd,msg,w,l
	.if msg==WM_TIMER
		invoke TestDraw,hWnd
	.elseif msg==WM_CLOSE
		invoke PostQuitMessage,0
	.elseif msg==WM_PAINT
		invoke ValidateRect,hWnd,0
		invoke TestDraw,hWnd
	.elseif msg==WM_KEYDOWN && w==VK_ESCAPE
		invoke PostQuitMessage,0
	.else
		invoke DefWindowProc,hWnd,msg,w,l
		ret
	.endif
	xor eax,eax
	ret
WinProc endp
;------------------------------------------------------------------/






;===========================[ main procedure ]=======================================[
main proc
	local msg:MSG
	;-------[ init sDraw, and load images ]------------------[
	invoke InitSDraw,1200,900
	;--------------------------------------------------------/
	;------[ make the main window ]-----------------------------[
	invoke MakeOneWindow,1200,900,WinProc,addr wndTitle,WND_STYLE
	;-----------------------------------------------------------/
	invoke SetTimer,eax,1,20,0
	invoke sdSpriteFromBitmapFile,addr lpszPoint
	mov pPointBmp,eax
	invoke sdSpriteFromILBFile,addr lpszKnob4
	mov knob4,eax
	
	;---[ message-loop ]-----------------------[
	.while TRUE
		invoke GetMessage, ADDR msg,0,0,0
		.BREAK .IF (!eax)
		invoke TranslateMessage, ADDR msg
		invoke DispatchMessage, ADDR msg
	.endw
	;------------------------------------------/
	
	invoke FreeSDraw
	
	ret
main endp
;====================================================================================/






start:
	invoke main
	invoke ExitProcess,0
end start
