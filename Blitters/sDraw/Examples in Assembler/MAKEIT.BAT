@echo off

\masm32\bin\ml /c /coff /nologo Example1.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS Example1.obj


\masm32\bin\ml /c /coff /nologo Example2.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS Example2.obj
pause