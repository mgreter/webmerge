@echo off

if not exist 64 mkdir 64

cd 64

..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-gm-x64.exe
..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-jre7-x64.exe
..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe
..\..\gitstall\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x64.exe

webmerge-gm-x64.exe
webmerge-jre7-x64.exe
webmerge-utils-x32.exe
webmerge-ruby-sass-x64.exe

cd ..