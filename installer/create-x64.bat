@echo off

if not exist files\dist mkdir files\dist

cd files\dist

copy /b ..\utils\7zCon.sfx + ..\64\gm.7z webmerge-gm-x64.exe
copy /b ..\utils\7zCon.sfx + ..\64\perl.7z webmerge-perl-x64.exe
copy /b ..\utils\7zCon.sfx + ..\64\ruby.7z webmerge-ruby-sass-x64.exe

cd ..\..

pause
