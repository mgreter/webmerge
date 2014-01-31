@echo off

if not exist release mkdir release

if exist release\installer-files-x32.7z del release\installer-files-x32.7z

files\utils\7z a release\installer-files-x32.7z files\utils\pathed.exe files\utils\wget.exe files\utils\unzip.exe files\utils\LICENSE install-x32.bat uninstall-x32.bat

cd release

copy /b ..\files\utils\7zS.sfx + ..\files\config\config-x32.txt + ..\release\installer-files-x32.7z webmerge-installer-x32.exe

cd ..\..

pause