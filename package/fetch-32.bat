@echo off

mkdir 32

cd 32

..\..\installer\files\utils\wget -c "http://webmerge.ocbnet.ch/portable/webmerge-perl-x32.exe"

webmerge-perl-x32.exe

cd ..