@echo off

if not exist release mkdir release

files\utils\7z a release\installer-files-x64.7z files\utils\pathed.exe files\utils\wget.exe files\utils\unzip.exe files\utils\LICENSE install-x64.bat uninstall-x64.bat

cd release

copy /b ..\files\utils\7zS.sfx + ..\files\config\config-x64.txt + ..\release\installer-files-x64.7z webmerge-installer-x64.exe

cd ..\..

pause