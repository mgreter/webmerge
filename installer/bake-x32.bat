@echo off

SET version=%~1

if "%version%" == "" SET version=master

if not exist release mkdir release

if exist release\installer-files-x32.7z del release\installer-files-x32.7z

files\utils\7z -mx9 a release\installer-files-x32.7z files\utils\pathed.exe files\utils\wget.exe files\utils\unzip.exe files\utils\LICENSE install-x32.bat uninstall-x32.bat

cd release

if exist ..\files\config\config-x32.txt del ..\files\config\config-x32.txt

echo ;!@Install@!UTF-8! >> ..\files\config\config-x32.txt
echo Title="Webmerge Portable (32bit)" >> ..\files\config\config-x32.txt
echo BeginPrompt="Do you want to install Webmerge Portable (%version%)?" >> ..\files\config\config-x32.txt
echo ExecuteFile="install-x32.bat" >> ..\files\config\config-x32.txt
echo ExecuteParameters="%version%" >> ..\files\config\config-x32.txt
echo ;!@InstallEnd@! >> ..\files\config\config-x32.txt

copy /b ..\files\utils\7zS.sfx + ..\files\config\config-x32.txt + ..\release\installer-files-x32.7z webmerge-installer-%version%-x32.exe

cd ..

echo created webmerge-installer-%version%-x32.exe
