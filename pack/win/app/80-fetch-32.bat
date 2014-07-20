@echo off

if not exist 32 mkdir 32

cd 32

call ..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-gm-x32.exe
call ..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-jre7-x64.exe
call ..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe
call ..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x32.exe

call webmerge-gm-x32.exe -y
call webmerge-jre7-x64.exe -y
call webmerge-utils-x32.exe -y
call webmerge-ruby-sass-x32.exe -y

cd ..