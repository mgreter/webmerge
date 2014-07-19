@echo off

if not exist 32 mkdir 32

cd 32

..\..\gitstall\files\utils\wget -c "http://webmerge.ocbnet.ch/portable/webmerge-perl-x32.exe"

webmerge-perl-x32.exe

cd ..