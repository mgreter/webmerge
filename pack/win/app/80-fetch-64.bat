@echo off

if not exist 64 mkdir 64

cd 64

call ..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-gm-x64.exe
call ..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-jre7-x64.exe
call ..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe
call ..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x64.exe

call webmerge-gm-x64.exe -y
call webmerge-jre7-x64.exe -y
call webmerge-utils-x32.exe -y
call webmerge-ruby-sass-x64.exe -y

cd ..