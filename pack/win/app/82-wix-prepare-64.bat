@echo off

cd 64

xcopy ..\..\..\..\res res /i /Y /Q /E
xcopy ..\..\..\..\conf conf /i /Y /Q /E
xcopy ..\..\..\..\vendor vendor /i /Y /Q /E
xcopy ..\..\..\..\example example /i /Y /Q /E

cd vendor
cd google
cd closure

call update

cd ..
cd ..

cd yahoo
cd yui

call update

cd ..
cd ..

cd ..
