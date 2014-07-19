@echo off

cd 32

xcopy ..\..\..\..\res res /i /Y /Q /E
xcopy ..\..\..\..\conf conf /i /Y /Q /E
xcopy ..\..\..\..\vendor vendor /i /Y /Q /E
xcopy ..\..\..\..\example example /i /Y /Q /E

cd ..
