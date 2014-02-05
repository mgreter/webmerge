@echo off

if not exist files\dist mkdir files\dist

cd files\dist

if exist ..\64\gm.7z copy /b ..\utils\7zCon.sfx + ..\64\gm.7z webmerge-gm-x64.exe
if exist ..\64\jre7.7z copy /b ..\utils\7zCon.sfx + ..\64\jre7.7z webmerge-jre7-x64.exe
if exist ..\64\perl.7z copy /b ..\utils\7zCon.sfx + ..\64\perl.7z webmerge-perl-x64.exe
if exist ..\64\ruby.7z copy /b ..\utils\7zCon.sfx + ..\64\ruby.7z webmerge-ruby-sass-x64.exe

cd ..\..

pause
