@echo off

cd 64

call xcopy ..\..\..\..\res res /i /Y /Q /E
call xcopy ..\..\..\..\conf conf /i /Y /Q /E
call xcopy ..\..\..\..\vendor vendor /i /Y /Q /E
call xcopy ..\..\..\..\example example /i /Y /Q /E

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

cd ..
