@echo off

if not exist 32 mkdir 32

cd 32

..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-gm-x32.exe
..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-jre7-x64.exe
..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe
..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x32.exe

webmerge-gm-x32.exe
webmerge-jre7-x64.exe
webmerge-utils-x32.exe
webmerge-ruby-sass-x32.exe

cd ..