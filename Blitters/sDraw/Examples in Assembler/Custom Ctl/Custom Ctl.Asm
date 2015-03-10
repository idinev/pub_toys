.586
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Custom Ctl.inc
include ..\..\sDraw.inc
includelib ..\..\sDraw.lib
include masm32.inc

.data
	wc WNDCLASSEX <>
	wndClass db "CustomX",0
	wndTitle db "CustomX ctl",0
	lpszImg1 db "add_active.ilb",0 ; was converted with PackToILB.exe from add_active.tga
	lpszImg2 db "add_active2.ilb",0
	
	
	sImg1 dd 0
	sImg2 dd 0
	isOver dd 0
	
.code



RegisterCustomX proc
	mov wc.cbSize,sizeof  wc
	
	push offset CustomX_WndProc
	pop wc.lpfnWndProc
	invoke LoadCursor,0,IDC_ARROW
	mov wc.hCursor,eax
	invoke GetModuleHandle,0
	mov wc.hInstance,eax
	mov wc.lpszClassName,offset wndClass
	invoke RegisterClassEx,addr wc
	ret
RegisterCustomX endp


CustomX_OnPaint proc hWnd
	invoke sdStart,hWnd
	jz _ret
	invoke GetSysColor,COLOR_3DFACE
	bswap eax
	shr eax,8
	;invoke sDrawRect,0,0,42,28,eax
	invoke sdFetchBackground
	
	mov eax,hWnd
	.if isOver==eax
		invoke sBltParam,0,0,42,28,0,0,sImg2
	.else
		invoke sBltParam,0,0,42,28,0,0,sImg1
	.endif
	invoke sdEnd
_ret:
	ret
CustomX_OnPaint endp
CustomX_WndProc proc hWnd,msg,w,l
	LOCAL tmouse:TRACKMOUSEEVENT
	LOCAL rect:RECT
	LOCAL pt:POINT
	.if msg==WM_PAINT
		invoke CustomX_OnPaint,hWnd
		invoke ValidateRect,hWnd,0
	.elseif msg==WM_MOUSEMOVE
		.if !isOver
			push hWnd
			pop isOver
			mov tmouse.cbSize,16
			mov tmouse.dwFlags,TME_LEAVE
			push hWnd
			pop tmouse.hwndTrack
			mov tmouse.dwHoverTime,HOVER_DEFAULT
			invoke TrackMouseEvent,addr tmouse
			jmp _invalidateParent
		.endif
	.elseif msg==WM_MOUSELEAVE
		mov isOver,0
		_invalidateParent:
		invoke GetWindowRect,hWnd,addr rect
		mov pt.x,0
		mov pt.y,0		
		invoke GetWindowLong,hWnd,GWL_HWNDPARENT
		push eax
		lea edx,pt
		invoke ScreenToClient,eax,edx
		mov eax,pt.x
		mov edx,pt.y
		add rect.left,eax
		add rect.top,edx
		add rect.right,eax
		add rect.bottom,edx		
		pop edx
		invoke InvalidateRect,edx,addr rect,1
	.else
		invoke DefWindowProc,hWnd,msg,w,l
		ret
	.endif
	xor eax,eax
	ret
CustomX_WndProc endp




start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    invoke InitCommonControls
    invoke CoInitialize,0
    invoke RegisterCustomX
    
    invoke InitSDraw,0,0
    invoke sdSpriteFromILBFile,addr lpszImg1
    mov sImg1,eax
    invoke sdSpriteFromILBFile,addr lpszImg2
    mov sImg2,eax
    
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke FreeSDraw
	invoke CoUninitialize
	invoke ExitProcess,0

;########################################################################

DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG

	.elseif eax==WM_COMMAND

	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

end start
