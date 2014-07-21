@echo off

if not exist 64 mkdir 64

cd 64

..\..\gitstall\files\utils\wget -c "http://webmerge.ocbnet.ch/portable/webmerge-perl-x64.exe"

webmerge-perl-x64.exe -y

cd ..