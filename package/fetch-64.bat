@echo off

mkdir 64

cd 64

..\..\installer\files\utils\wget -c "http://webmerge.ocbnet.ch/portable/webmerge-perl-x64.exe"

webmerge-perl-x64.exe

cd ..