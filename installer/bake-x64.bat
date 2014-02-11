@echo off

SET version=%~1

if "%version%" == "" SET version=master

if not exist release mkdir release

if exist release\installer-files-x64.7z del release\installer-files-x64.7z

files\utils\7z -mx9 a release\installer-files-x64.7z files\utils\pathed.exe files\utils\wget.exe files\utils\unzip.exe files\utils\LICENSE install-x64.bat uninstall-x64.bat

cd release

if exist ..\files\config\config-x64.txt del ..\files\config\config-x64.txt

echo ;!@Install@!UTF-8! >> ..\files\config\config-x64.txt
echo Title="Webmerge Portable (64bit)" >> ..\files\config\config-x64.txt
echo BeginPrompt="Do you want to install Webmerge Portable (%version%)?" >> ..\files\config\config-x64.txt
echo ExecuteFile="install-x64.bat" >> ..\files\config\config-x64.txt
echo ExecuteParameters="%version%" >> ..\files\config\config-x64.txt
echo ;!@InstallEnd@! >> ..\files\config\config-x64.txt

copy /b ..\files\utils\7zS.sfx + ..\files\config\config-x64.txt + ..\release\installer-files-x64.7z webmerge-installer-%version%-x64.exe

cd ..

echo created webmerge-installer-%version%-x64.exe
