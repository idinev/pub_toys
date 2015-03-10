LRESULT CALLBACK WindowProcedure (HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

HWND MakeOneWindow(long wid,long hei,char* lpszTitle,DWORD dwStyle){
	HWND hwnd;
    WNDCLASSEX wincl;

    /* The Window structure */
    wincl.hInstance = GetModuleHandle(0);
    wincl.lpszClassName = "OneWindowCls";
    wincl.lpfnWndProc = WindowProcedure;      /* This function is called by windows */
    wincl.style = 0;
    wincl.cbSize = sizeof (WNDCLASSEX);

    /* Use default icon and mouse-pointer */
    wincl.hIcon = LoadIcon (NULL, IDI_APPLICATION);
    wincl.hIconSm = LoadIcon (NULL, IDI_APPLICATION);
    wincl.hCursor = LoadCursor (NULL, IDC_ARROW);
    wincl.lpszMenuName = NULL;                 /* No menu */
    wincl.cbClsExtra = 0;                      /* No extra bytes after the window class */
    wincl.cbWndExtra = 0;                      /* structure or the window instance */
    /* Use Windows's default color as the background of the window */
    wincl.hbrBackground = (HBRUSH) NULL;

    /* Register the window class, and if it fails quit the program */
    if (!RegisterClassEx (&wincl))
        return 0;

    /* The class is registered, let's create the program*/
    hwnd = CreateWindowEx (
           0,                   /* Extended possibilites for variation */
           wincl.lpszClassName, /* Classname */
           lpszTitle,
           dwStyle, /* default window */
           CW_USEDEFAULT,       /* Windows decides the position */
           CW_USEDEFAULT,       /* where the window ends up on the screen */
           wid,                 /* The programs width */
           hei,                 /* and height in pixels */
           0,        /* The window is a child-window to desktop */
           NULL,                /* No menu */
           wincl.hInstance,       /* Program Instance handler */
           NULL                 /* No Window Creation data */
           );
	return hwnd;
}

void MessageLoop(){
	MSG messages;
	while (GetMessage (&messages, NULL, 0, 0))
    {
        TranslateMessage(&messages);
        DispatchMessage(&messages);
    }
}
