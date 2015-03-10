;BASE_SKIP_CLASSES equ 1
;include \masm32\ultrano\bank\base.inc

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

if ALLOW_EXTERNAL_LIBS
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib
endif
;------------------------------------------/

UseAll textequ <uses eax ebx ecx edx esi edi>
UseMost textequ <uses ebx ecx edx esi edi>


SetBounds macro Whats,Mins,Maxs
local _donene,_greatat
	cmp Whats,Mins
	jge _greatat
	mov Whats,Mins
	jmp _donene
	_greatat:
	cmp Whats,Maxs
	jl _donene
	mov Whats,Maxs
	_donene:
endm

$invoke MACRO Fun:REQ, A:VARARG
	IFB <A>
		invoke Fun
	else
		invoke Fun, A
	endif
	exitm <eax>
ENDM

MessageLoop macro
	.while TRUE
		invoke GetMessage, ADDR msg,NULL,0,0
		.BREAK .IF (!eax)
		invoke TranslateMessage, ADDR msg
		invoke DispatchMessage, ADDR msg
	.endw
endm


multi macro What:VARARG
	local txt1,char1
	txt1 textequ <>
	forc char1,<What>
		ifidn <char1>,<|>
			txt1
			txt1 CATSTR <>
		else
			txt1 CATSTR txt1,<char1>
		endif
	endm
	txt1
endm


Clear macro What
	local How
	How=sizeof What
	if How eq 0
		exitm
	endif
	pushi eax,ecx,edi
	lea edi,What
	xor eax,eax
	if How ge 4
		mov ecx,How/4
		How = How - (How/4)*4
		rep stosd
	endif
	if How
		mov ecx,How
		rep stosb
	endif
	
	popi eax,ecx,edi
endm

m2m MACRO M1, M2
        push M2
        pop  M1
ENDM	

pushi macro Whats:VARARG
	local txt1
	for txt1,<Whats>
		push txt1
	endm
endm
popi macro arglist:VARARG
	local txt1
	LOCAL txt, arg
	txt TEXTEQU <>
	FOR arg, <arglist>
		txt CATSTR <arg>, <!,>, txt
	endm
	txt SUBSTR  txt, 1, @SizeStr( %txt ) - 1
	%for txt1,<txt>
		pop txt1
	endm
endm

poppi textequ <popi>

malloc MACRO How:REQ
	invoke malloc_func,How
	exitm <eax>
ENDM
	
free MACRO What
	invoke free_func,What
ENDM
T macro Text:VARARG
        local szText
        .data
        szText byte Text, 0
        .code
        exitm <offset szText>        
endm

;====================================================================================================

HEAP_ZERO_MEMORY equ 00000008h      

.data
	HEAP2 dd 0
.code

HeapCreate proto :DWORD,:DWORD,:DWORD
HeapAlloc proto :DWORD,:DWORD,:DWORD
HeapFree proto :DWORD,:DWORD,:DWORD
HeapSize proto :DWORD,:DWORD,:DWORD
HeapReAlloc proto :DWORD,:DWORD,:DWORD,:DWORD
memmove  proto Where:DWORD,From:DWORD,Len:DWORD

malloc_func proc PRIVATE uses ebx ecx edx esi edi How
	.if !HEAP2
		invoke HeapCreate,0,10000,0
		mov HEAP2,eax
	.endif
	invoke HeapAlloc,HEAP2,HEAP_ZERO_MEMORY,How	
	ret
malloc_func endp
	
free_func proc PRIVATE uses eax ebx ecx edx esi edi What
	invoke HeapFree,HEAP2,0,What
	ret
free_func endp


memmove proc PRIVATE uses ecx esi edi Where,From,Len
	cld
	mov esi,From
	mov edi,Where
	mov ecx,Len
	shr ecx,2
	rep movsd
	mov ecx,Len
	and ecx,3
	rep movsb
	ret
memmove endp
memclone proc PRIVATE uses ebx ecx edx esi edi pSrc,dwSize
	.if !HEAP2
		invoke HeapCreate,0,10000,0
		mov HEAP2,eax
	.endif
	invoke HeapAlloc,HEAP2,0,dwSize
	.if eax
		invoke memmove,eax,pSrc,dwSize
	.endif
	ret
memclone endp






;=====[[ Unpack >>===\

;
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;You can change MAX_BITS from 10 to 14
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;

MAX_BITS = 14                            ;Maximum amount of bits in the
					 ;output symbol. _Size_, _time_
					 ;and _compression_ is directly
                                         ;dependant from this number
                                         ;
BITS_DEPENDED_BUFF_SIZE = (1 shl MAX_BITS) ;Size of the buffer for dictionary
                                         ;
COMPR_DICT_ITEM_SIZE   = (2+2+1)         ;sizeof(TableItem)
DECOMPR_DICT_ITEM_SIZE = (2+1)           ;sizeof(same but for LZD)
                                         ;
COMPR_BUFFER_SIZE   = (COMPR_DICT_ITEM_SIZE*BITS_DEPENDED_BUFF_SIZE)   ;
                                         ;Size of the compression buffer
                                         ;
DECOMPR_BUFFER_SIZE = (DECOMPR_DICT_ITEM_SIZE*BITS_DEPENDED_BUFF_SIZE) ;
                                         ;Size of the decompression buffer
                                         ;



;
;=============================================================================
;LZ32Decompression subroutines.
;All rights may be reserved by SexyDufus
;Disassembled by IDA v3.xx with little help of Green Monster ;-)
;==============================================================================
;
;Interface:
;int   lz_decompresss(char *inbuf, char *outbuf, int size, char *buf)
;
;-----------------------------------------------------------------------------
;Decompress data from inbuf, write output to outbuf.
;External buffer (buf) used for dictionary.
;Returns number of bytes placed in outbuf.
;=============================================================================
;


VarFrame        struc                      ;
vf_Const01FF    dw ?                       ;Mask (perverted)
vf_Const03FF    dw ?                       ;Other one
vf_Const07FF    dw ?                       ;Third
vf_Const0FFF    dw ?                       ;Last
                                           ;
vf_Sym1         dw ?                       ;Symbols
vf_Sym2         dw ?                       ;
vf_Sym3         dw ?                       ;
                                           ;
vf_FreeSym      dw ?                       ;Free symbol
vf_CharCount    dw ?                       ;Character count
vf_DictSize     dw ?                       ;Dictionary size
vf_BitSize      dw ?                       ;Bits in char
vf_SimpleChar   db ?                       ;Character
vf_CharToLink   db ?                       ;explains itself
                                           ;
vf_InBufRelPos  dw ?                       ;Position in the input buffer
field_1A        dw ?                       ;
vf_OutBufPos    dd ?                       ;Position in the output buffer
field_20        dw ?                       ; Ultrano:2 bytes of return address
field_22        dw ?                       ; Ultrano:2 more bytes of return address
                                           ;Parameters
vf_InBuf        dd ?                       ;char *inbuf
vf_OutBuf       dd ?                       ;char *outbuf
vf_SuxxSize     dd ?                       ;char *size (not used) ; Ultrano: we never look how big the buffer is
vf_Malloced     dd ?                       ;char *buf (dictionary)
VarFrame        ends                       ;
                                           ;
;=============================================================================
;Main subroutine
;=============================================================================
lz_decompress   proc near                  ;
                sub     eax, eax           ; now eax=0
                push    eax                ; vf_OutBufPos=0
                push    eax                ; vf_InBufRelPos=0
                push    9                  ; vf_CharToLink=0, vf_SimpleChar=0,vf_BitSize=9
                push    2000000h           ; vf_DictSize=512, vf_CharCount=0
                push    1020000h           ; vf_freeSym=0x102,vf_Sym3=0
                push    eax                ; vf_Sym1=0,vf_Sym2=0
                push    0FFF07FFh          ;Perverted masks. vf_Const0FFF=0xFFF, vf_Const07FF=0x7FF
                push    3FF01FFh           ;vf_Const03FF=0x3FF,vf_Const01FF=0x1FF
                mov     ebp, esp           ; ebp - address to start of structure!
                                           ;
get_next_sym:                              ;
                call    Get_Sym            ;Get symbol
                cmp     ax, 101h           ; 101h - end of data
                jz      lzd_exit           ;
                cmp     ax, 100h           ; 100h - dictionary reset
                jnz     short other_syms   ;
                                           ;
                call    lzd_init           ;Reset
                                           ;
                call    Get_Sym            ;
                mov     [ebp+VarFrame.vf_Sym1], ax        ;
                mov     [ebp+VarFrame.vf_Sym2], ax        ;
                mov     [ebp+VarFrame.vf_CharToLink], al  ;
                mov     [ebp+VarFrame.vf_SimpleChar], al  ;
                call    Save_Char          ;First symbol is always simple
                jmp     short get_next_sym ;
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                                           ;
other_syms:                                ;
                mov     [ebp+VarFrame.vf_Sym1], ax      ;
                mov     [ebp+VarFrame.vf_Sym3], ax      ;
                cmp     ax, [ebp+VarFrame.vf_FreeSym]   ;Symbol is already in 
                jl      short already_in_dict           ;dictionary?
                                                        ;
                movzx   eax, [ebp+VarFrame.vf_Sym2]     ;
                mov     [ebp+VarFrame.vf_Sym1], ax      ;
                movzx   eax, [ebp+VarFrame.vf_SimpleChar]
                push    eax                             ;Leave it in stack
                inc     [ebp+VarFrame.vf_CharCount]     ;
                                                        ;
already_in_dict:                                        ;
                cmp     [ebp+VarFrame.vf_Sym1], 0FFh    ;
                jle     short one_time_again            ;
;                                                       ;
                movzx   ebx, [ebp+VarFrame.vf_Sym1]     ;
                call    _Calc_Sym_Pos                   ;
                mov     al, [ebx+2]                     ;
                push    eax                             ;Create chain in stack
                inc     [ebp+VarFrame.vf_CharCount]     ;
                movzx   eax, word ptr [ebx]             ;
                mov     [ebp+VarFrame.vf_Sym1], ax      ;
                jmp     short already_in_dict           ;
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                                                        ;
one_time_again:                                         ;
                movzx   eax, [ebp+VarFrame.vf_Sym1]        ;
                mov     [ebp+VarFrame.vf_SimpleChar], al   ;
                mov     [ebp+VarFrame.vf_CharToLink], al   ;
                push    eax                                ;
                inc     [ebp+VarFrame.vf_CharCount]        ;
                movzx   ecx, [ebp+VarFrame.vf_CharCount]   ;
                jcxz    no_chars                           ;
                                                           ;
save_from_stack:                                           ;Write chain from stack
                pop     eax                                ;
                call    Save_Char                          ;into output stream
                loop    save_from_stack                    ;
                                                           ;
no_chars:                                                  ;
                mov     [ebp+VarFrame.vf_CharCount], cx    ;
                                                           ;
                call    Add_Chain                          ;
                movzx   eax, [ebp+VarFrame.vf_Sym3]        ;
                mov     [ebp+VarFrame.vf_Sym2], ax         ;
                movzx   ebx, [ebp+VarFrame.vf_FreeSym]     ;
;                                                          ;
                cmp     bx, [ebp+VarFrame.vf_DictSize]     ;
                jl      get_next_sym                       ;
;                                                          ;
;-------->replaced<-----------------                        ;
;                cmp     [ebp+VarFrame.vf_BitSize], 0Ch     ;
                cmp     [ebp+VarFrame.vf_BitSize], MAX_BITS ;Check amount of bits
;-------->end<---------------------                        ;
                jz      get_next_sym                       ;
                                                           ;
                inc     [ebp+VarFrame.vf_BitSize]          ;Increase it
                shl     [ebp+VarFrame.vf_DictSize], 1      ;And dictionary size
                jmp     get_next_sym                       ;
; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                                                           ;
lzd_exit:                                                  ;
                xchg    eax, edi                           ;EAX = end-start = size
                sub     eax, [ebp+VarFrame.vf_OutBuf]      ;
                add     esp, 20h                           ;
                retn    10h                                ;
lz_decompress   endp                                       ;
                                                           ;
;-----------------------------------------------------------------------------
;Calculate address of dictionary element from symbol nubmer
;-----------------------------------------------------------------------------
_Calc_Sym_Pos   proc near                                  ;
                lea     ebx, [ebx+ebx*2]                   ;EBX *= 3
                add     ebx, [ebp+VarFrame.vf_Malloced]    ;
                retn                                       ;
_Calc_Sym_Pos   endp                                       ;
                                                           ;
;-----------------------------------------------------------------------------
;Read symbol of variable size from the input stream
;-----------------------------------------------------------------------------
Get_Sym         proc near                                 ;
                movzx   eax, [ebp+VarFrame.vf_BitSize]    ; eax = vf_BitSize
                add     eax, dword ptr [ebp+VarFrame.vf_InBufRelPos] ;eax+=
                xchg    eax, dword ptr [ebp+VarFrame.vf_InBufRelPos]
                mov     ecx, 8                            ;
                sub     edx, edx                          ;
                div     ecx                               ; /8 (bits per byte)
                add     eax, [ebp+VarFrame.vf_InBuf]      ;
                xchg    eax, esi                          ;
                lodsw                                     ;Load 3 bytes
                movzx   ebx, ax                           ;
                lodsb                                     ;
                movzx   ecx, dx                           ;
                jcxz    getsym_exit                       ;
                                                          ;Select what we need
select_bits:                                              ;
                shr     al, 1                             ;
                rcr     bx, 1                             ;
                loop    select_bits                       ;
                                                          ;
getsym_exit:                                              ;
                movzx   eax, bx                           ;
                movzx   ebx, [ebp+VarFrame.vf_BitSize]    ;
                                                          ;
;------------>replaced<---------------------------------  ;
;                sub     ebx, 9                           ;
;                and     ax, [ebp+ebx*2+VarFrame.vf_Const01FF]
                                                          ;
                mov     cl, bl                            ;
                xor     ebx, ebx                          ;
                inc     ebx                               ;
                shl     bx, cl                            ;
                dec     bx                                ;
                and     ax, bx                            ;
                                                          ;
;------------>end<--------------------------------------  ;
                                                          ;
                retn                                      ;
Get_Sym         endp                                      ;
                                                          ;
;-----------------------------------------------------------------------------
;Dictionary reset
;-----------------------------------------------------------------------------
lzd_init        proc near                                 ;
                mov     [ebp+VarFrame.vf_BitSize], 9      ;Size in bits
                mov     [ebp+VarFrame.vf_DictSize], 200h  ;Dictionary size
                mov     [ebp+VarFrame.vf_FreeSym], 102h   ;First free symbol
                retn                                      ;
lzd_init        endp                                      ;
                                                          ;
;-----------------------------------------------------------------------------
;Write char into output stream
;-----------------------------------------------------------------------------
Save_Char       proc near                                 ;
                mov     edi, [ebp+VarFrame.vf_OutBufPos]  ;
                add     edi, [ebp+VarFrame.vf_OutBuf]     ;
                stosb                                     ;
                inc     [ebp+VarFrame.vf_OutBufPos]       ;
                retn                                      ;
Save_Char       endp                                      ;
                                                          ;
;-----------------------------------------------------------------------------
;Write links into the dictionary
;-----------------------------------------------------------------------------
Add_Chain       proc near                                 ;
                movzx   ebx, [ebp+VarFrame.vf_FreeSym]    ;
                call    _Calc_Sym_Pos                     ;
                movzx   eax, [ebp+VarFrame.vf_CharToLink] ;
                mov     [ebx+2], al                       ;
                movzx   eax, [ebp+VarFrame.vf_Sym2]       ;
                mov     [ebx], ax                         ;
                inc     [ebp+VarFrame.vf_FreeSym]         ;
                retn                                      ;
Add_Chain       endp                                      ;
                                                          ;

unpack proc uses ebx ecx edx esi edi UnpackWhat,UnpackWhere,PackedSize
	local dictionary
	.if !PackedSize
		xor eax,eax
		ret
	.endif
	invoke malloc_func,COMPR_BUFFER_SIZE
	mov dictionary,eax
	push ebp
	pushi dictionary,PackedSize,UnpackWhere,UnpackWhat
	call lz_decompress
	pop ebp
	invoke free_func,dictionary
	ret
unpack endp
;=======/