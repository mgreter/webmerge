@echo off

if not exist files\dist mkdir files\dist

cd files\dist

copy /b ..\utils\7zCon.sfx + ..\32\gm.7z webmerge-gm-x32.exe
copy /b ..\utils\7zCon.sfx + ..\32\perl.7z webmerge-perl-x32.exe
copy /b ..\utils\7zCon.sfx + ..\32\utils.7z webmerge-utils-x32.exe
copy /b ..\utils\7zCon.sfx + ..\32\ruby.7z webmerge-ruby-sass-x32.exe

cd ..\..

pause