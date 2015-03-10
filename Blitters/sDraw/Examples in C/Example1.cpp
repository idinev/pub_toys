#include <windows.h>


#include "ExampleBase.h"
#include "../sDraw.h"

//-------------[ data ]-------------------------------[
sSprite* pBack;
sSprite* pBall;
//----------------------------------------------------/




void DoDraw(HWND hWnd){
	POINT BallPos;
	if(!sdStart(hWnd))return;	// always return if failed! sdStart fails when the window is not visible

	GetCursorPos(&BallPos);
	ScreenToClient(hWnd,&BallPos);

	sdSetSourceSprite(pBack);
	sBlt(0,0,400,300,0,0);
	
	sdSetSourceSprite(pBall);
	sBltAlpha(BallPos.x,BallPos.y,100,100,0,0,300);
	
	
	
	sDrawRectROP(100,100,400,300,(GetTickCount()>>3)&255,SD_ADDSAT);

	sdEnd();
}



LRESULT CALLBACK WindowProcedure (HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg)
    {
	case WM_CLOSE:
		PostQuitMessage(0);
		break;
	case WM_PAINT:
		ValidateRect(hwnd,0); // Note, we should validate.
		DoDraw(hwnd);	// draw the window
		break;
	case WM_MOUSEMOVE:
		DoDraw(hwnd); // let's redraw the window
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
	InitSDraw(400,300);
	//------[ load some images ]-----------------------[
	pBack = sdSpriteFromILBFile("../Media/back.ilb");
	pBall = sdSpriteFromILBFile("../Media/ball.ilb");
	//-------------------------------------------------/
    MakeOneWindow(400,300,"hello sDraw!",(WS_POPUP | WS_CAPTION | WS_VISIBLE | WS_SYSMENU));
    MessageLoop();
    FreeSDraw();
    return 0;
}



