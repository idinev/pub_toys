#include <windows.h>
/***********************************************

	Advanced example of sDraw,
	Using clippers to draw "virtual windows"


************************************************/
#include "ExampleBase.h"
#include "../sDraw.h"

//-------------[ data ]-------------------------------[
sSprite* pBack;
sSprite* pCWbmp;
sSprite* pMenu1;

#define CWWID 220
#define CWHEI 150

#define MAX_NUM_CW 10

bool g_IsMouseCaptured=0;
POINT g_CapturePoint,g_CurCPoint;
HWND hwndMain;
//----------------------------------------------------/


class CustWND{
public:
	long x,y,wid,hei;
	long alpha;
	HWND ParentRealWnd;

	CustWND(HWND hWnd,long ix,long iy){
		ParentRealWnd=hWnd;
		x=ix;
		y=iy;
		wid=CWWID;
		hei=CWHEI;
		alpha=256;
	}
	bool hits(long ix,long iy){
		return (ix>=x) && (iy>=y) && (ix<x+wid) && (iy<y+hei);
	}
	void draw();
	void onTick();
	void onMouseDown(long ix,long iy);
	void focus();
	void startDrag();
};

CustWND *AllCW[MAX_NUM_CW]={0};
#define FocusedCW (AllCW[0]) // highest in Z-order




CustWND* GetWndFromPos(long x,long y){
	CustWND *curW;
	for(long i=0;i<MAX_NUM_CW;i++){
		if(!(curW=AllCW[i]))continue;
		if(curW->hits(x,y))return curW;
	}
	return 0;
}


void CustWND::draw(){
	SD_TransparentColor = 0;
	sdSetSourceSprite(pCWbmp);
	sBltTransAlpha(0,0,CWWID,CWHEI,0,0,alpha);
	if(this!=FocusedCW){
		if(GetWndFromPos(g_CurCPoint.x,g_CurCPoint.y)==this){
			sBltAddFade(0,0,CWWID,CWHEI,0,0,100);
		}
	}
}
void CustWND::onTick(){
	if(FocusedCW==this)return;
	alpha-=10;
	if(alpha<80)alpha=80;
}
void CustWND::onMouseDown(long ix,long iy){
	/*if(iy<40)*/startDrag();	
}

void CustWND::startDrag(){
	focus();
	SetCapture(ParentRealWnd);
	g_IsMouseCaptured=true;
	GetCursorPos(&g_CapturePoint);
	g_CapturePoint.x-=FocusedCW->x;
	g_CapturePoint.y-=FocusedCW->y;
}

void CustWND::focus(){
	long i;
	if(this==FocusedCW)return;
	
	for(i=MAX_NUM_CW;i>1;){
		i--;
		if(AllCW[i]==this){
			AllCW[i]=AllCW[i-1];
			AllCW[i-1]=this;
		}
	}
	FocusedCW=this;
	alpha=256;
}

void TickAllCW(){
	long i;
	CustWND *curW;
	for(i=MAX_NUM_CW;i;){
		if(!(curW=AllCW[--i]))continue;
		curW->onTick();
	}
}

void DrawAllCW(){
	long i;
	CustWND *curW;
	GetCursorPos(&g_CurCPoint);
	g_CurCPoint.y-=pMenu1->hei;
	ScreenToClient(hwndMain,&g_CurCPoint);
	for(i=MAX_NUM_CW;i;){
		if(!(curW=AllCW[--i]))continue;
		sdEnterClip(curW->x,curW->y,curW->wid,curW->hei);
		curW->draw();
		sdLeaveClip();
	}
}

bool OnMouseDown(HWND hWnd,long x,long y){
	CustWND *curW;
	if(y>= pMenu1->hei){
		y-= pMenu1->hei;
		curW = GetWndFromPos(x,y);
		if(curW){
			curW->focus();
			curW->onMouseDown(x - curW->x,y - curW->y);
		}
	}
	return false;
}

CustWND *AddNewCW(HWND hWndParent){
	CustWND *result;
	for(long i=0;i<MAX_NUM_CW;i++){
		if(AllCW[i])continue;
		result = new CustWND(hWndParent,i*20,i*20);
		AllCW[i] = result;
		result->focus();
		return result;
	}
	return NULL;
}


void DoDraw(HWND hWnd){
	if(!sdStart(hWnd))return;	// always return if failed! sdStart fails when the window is not visible
	//-----[ draw top menu ]--------------------[
	sdEnterClip(0,0,2000,pMenu1->hei);
		sdSetSourceSprite(pMenu1);
		sDrawRect(0,0,1300,100,0);
		if(g_IsMouseCaptured)sDrawRect(0,0,1300,100,GetTickCount());
		sBltTile(0,0,1300,pMenu1->hei,0,0,128,pMenu1->hei,0,0);
		sBltTint(30,0,134,23,131,0,GetTickCount()>>4);
		sBltTint(300,3,285,23,280,0,255);
	sdLeaveClip();
	//------------------------------------------/
	//------[ draw "client" area... ]---------------[
	sdEnterClip(0,pMenu1->hei,2000,2000);
		sdSetSourceSprite(pBack);
		sBltTile(0,0,1300,1000,0,0,64,64,0,0);
		DrawAllCW();
	sdLeaveClip();
	//----------------------------------------------/
	sdEnd();
}



LRESULT CALLBACK WindowProcedure (HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	POINT cc;
    switch (msg)
    {
	case WM_CLOSE:
		PostQuitMessage(0);
		break;
	case WM_PAINT:
		ValidateRect(hwnd,0);
		DoDraw(hwnd);
		break;
	case WM_LBUTTONDOWN:
		OnMouseDown(hwnd,LOWORD(lParam),HIWORD(lParam));
		break;
	case WM_MOUSEMOVE:
		if(g_IsMouseCaptured && FocusedCW){
			GetCursorPos(&cc);
			FocusedCW->x = cc.x-g_CapturePoint.x;
			FocusedCW->y = cc.y-g_CapturePoint.y;
			DoDraw(hwnd);
		}
		break;
	case WM_LBUTTONUP:
		ReleaseCapture();
		g_IsMouseCaptured=false;
		break;
	case WM_TIMER:
		TickAllCW();
		DoDraw(hwnd);
		break;
	default:
		return DefWindowProc (hwnd, msg, wParam, lParam);
    }
	
    return 0;
}



int WINAPI WinMain (HINSTANCE hThisInstance,
                    HINSTANCE hPrevInstance,
                    LPSTR lpszArgument,
                    int nFunsterStil)
					
{
	InitSDraw(0,0);
	//------[ load some images ]-----------------------[
	//SetCurrentDirectory(".."); //debug.remove
	pBack = sdSpriteFromBitmapFile("../Media/back2.bmp");
	pCWbmp = sdSpriteFromILBFile("../Media/CustWindow.ilb");
	pMenu1 = sdSpriteFromBitmapFile("../Media/menu1.bmp");
	sdPreprocessSprite(pMenu1,SDPREPR_ALPHA_FROM_COLOR,0);
	//-------------------------------------------------/
    hwndMain = MakeOneWindow(600,400,"Drag and drop windows",(WS_OVERLAPPEDWINDOW | WS_CAPTION | WS_VISIBLE | WS_SYSMENU));
	AddNewCW(hwndMain);
	AddNewCW(hwndMain);
	AddNewCW(hwndMain);
	AddNewCW(hwndMain);
	SetTimer(hwndMain,1,50,0);
    MessageLoop();
    FreeSDraw();
    return 0;
}




