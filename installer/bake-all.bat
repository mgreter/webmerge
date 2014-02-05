@echo off

git describe --abbrev=0 > git-tag.txt
SET /p gitversion=<git-tag.txt
del git-tag.txt

echo %version%

call bake-x32.bat %gitversion%
call bake-x64.bat %gitversion%
call bake-x32.bat develop
call bake-x64.bat develop
call bake-x32.bat master
call bake-x64.bat master

pause