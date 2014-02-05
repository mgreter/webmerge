@echo off

if not exist files\dist mkdir files\dist

cd files\dist

if exist ..\32\gm.7z copy /b ..\utils\7zCon.sfx + ..\32\gm.7z webmerge-gm-x32.exe
if exist ..\32\jre7.7z copy /b ..\utils\7zCon.sfx + ..\32\jre7.7z webmerge-jre7-x64.exe
if exist ..\32\perl.7z copy /b ..\utils\7zCon.sfx + ..\32\perl.7z webmerge-perl-x32.exe
if exist ..\32\ruby.7z copy /b ..\utils\7zCon.sfx + ..\32\ruby.7z webmerge-ruby-sass-x32.exe
if exist ..\32\utils.7z copy /b ..\utils\7zCon.sfx + ..\32\utils.7z webmerge-utils-x32.exe

cd ..\..

pause