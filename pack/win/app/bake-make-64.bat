@echo off

git describe --tags --abbrev=0 > git-tag.txt
SET /p gitversion=<git-tag.txt
del git-tag.txt

call set gitversion=%%gitversion:v=%%

echo Baking %gitversion% (64 bit)

call bake-arch.bat 64

pause
