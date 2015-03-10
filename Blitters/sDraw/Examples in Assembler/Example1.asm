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
	
	lpszBall db "..\Media\Ball.ilb",0
	lpszBack db "..\Media\back.ilb",0
	
	pBall dd 0
	pBack dd 0

	
.code

TestDraw proc hWnd
	local BallPos:POINT
	
	invoke sdStart,hWnd
	jz _ret
	

	invoke GetCursorPos,addr BallPos
	invoke ScreenToClient,hWnd,addr BallPos
	sub BallPos.x,50
	sub BallPos.y,50
	
	
	invoke sdSetSourceSprite,pBack
	invoke sBlt,0,0,400,300,0,0
	
	invoke sdSetSourceSprite,pBall
	invoke sBltAlpha,BallPos.x,BallPos.y,100,100,0,0,300
	
	
	invoke GetTickCount
	shr eax,3
	and eax,255
	invoke sDrawRectROP,100,100,400,300,eax,SD_ADDSAT
	
	invoke sdEnd
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
	.if msg==WM_CLOSE
		invoke PostQuitMessage,0
	.elseif msg==WM_PAINT
		invoke ValidateRect,hWnd,0
		invoke TestDraw,hWnd
	.elseif msg==WM_MOUSEMOVE
		invoke TestDraw,hWnd
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
	invoke InitSDraw,400,300
	invoke sdSpriteFromILBFile,addr lpszBall
	mov pBall,eax
	invoke sdSpriteFromILBFile,addr lpszBack
	mov pBack,eax
	;--------------------------------------------------------/
	;------[ make the main window ]-----------------------------[
	invoke MakeOneWindow,400,300,WinProc,addr wndTitle,WND_STYLE
	;-----------------------------------------------------------/
	
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
