@echo off

echo Installing webmerge 64-bit portable

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

if not exist files\64 mkdir files\64

cd files\64

..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-gm-x64.exe
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-perl-x64.exe
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x64.exe
..\utils\wget --no-check-certificate -c https://github.com/mgreter/webmerge/archive/master.zip -O master.zip
..\utils\wget "http://dl.google.com/closure-compiler/compiler-latest.zip"

cd ..\..

if not exist 64 mkdir 64

cd 64

..\files\64\webmerge-gm-x64.exe -y
..\files\64\webmerge-perl-x64.exe -y
..\files\64\webmerge-utils-x32.exe -y
..\files\64\webmerge-ruby-sass-x64.exe -y

if exist webmerge rmdir webmerge /s /q
..\files\utils\unzip -o ..\files\64\master.zip
rename webmerge-master webmerge

..\files\utils\unzip -o "..\files\64\compiler-latest.zip" -d webmerge\scripts\google\closure

cd ..

echo Remove old global paths (ignore warnings)

files\utils\pathed -r "%CD%\32\webmerge"
files\utils\pathed -r "%CD%\64\webmerge"

echo Add global path "%CD%\64\webmerge"

files\utils\pathed -a "%CD%\64\webmerge"

REM cscript files\vbs\DelFromSystemPath.vbs //Nologo "%CD%\32\webmerge"
REM cscript files\vbs\DelFromSystemPath.vbs //Nologo "%CD%\64\webmerge"

REM cscript files\vbs\AddToSystemPath.vbs //Nologo "%CD%\64\webmerge"

echo Finished installing webmerge 64-bit portable

pause