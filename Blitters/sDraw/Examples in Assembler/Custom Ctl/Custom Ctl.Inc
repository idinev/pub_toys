
include windows.inc
include kernel32.inc
include user32.inc
include Comctl32.inc
include shell32.inc
include debug.inc


includelib kernel32.lib
includelib user32.lib
includelib Comctl32.lib
includelib shell32.lib
includelib debug.lib

DlgProc			PROTO	:HWND,:UINT,:WPARAM,:LPARAM

CoInitialize proto :DWORD
CoUninitialize proto

.const

IDD_DIALOG1			equ 101

;#########################################################################

.data?

hInstance			dd ?

;#########################################################################
