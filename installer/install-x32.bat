@echo off

echo Installing webmerge 32-bit portable

:CheckOS
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT
SET installdir=%PROGRAMFILES(X86)%
GOTO GotOS

:32BIT
SET installdir=%PROGRAMFILES%
GOTO GotOS

:GotOS

net session >nul 2>&1
if %errorLevel% == 0 GOTO gotAdmin

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

echo Installing into "%installdir%"

pushd "%CD%"
CD /D "%~dp0"

if not exist files\32 mkdir files\32

cd files\32

..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-gm-x32.exe
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-perl-x32.exe
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x32.exe
..\utils\wget --no-check-certificate -c https://github.com/mgreter/webmerge/archive/master.zip -O master.zip
..\utils\wget "http://dl.google.com/closure-compiler/compiler-latest.zip"

if not exist "%installdir%\webmerge" mkdir "%installdir%\webmerge"

cd "%installdir%\webmerge"

"%~dp0\files\32\webmerge-gm-x32.exe" -y
"%~dp0\files\32\webmerge-perl-x32.exe" -y
"%~dp0\files\32\webmerge-utils-x32.exe" -y
"%~dp0\files\32\webmerge-ruby-sass-x32.exe" -y

if exist webmerge rmdir webmerge /s /q
"%~dp0\files\utils\unzip" -o "%~dp0\files\32\master.zip"
rename webmerge-master webmerge

"%~dp0\files\utils\unzip" -o "%~dp0\files\32\compiler-latest.zip" -d webmerge\scripts\google\closure

echo Remove old global paths (ignore warnings)

"%~dp0\files\utils\pathed" -r "%PROGRAMFILES%\webmerge\webmerge"
"%~dp0\files\utils\pathed" -r "%PROGRAMFILES(X86)%\webmerge\webmerge"

echo Add global path "%installdir%\webmerge"

"%~dp0\files\utils\pathed" -a "%installdir%\webmerge\webmerge"

echo Finished installing webmerge 32-bit portable
echo Installed at "%installdir%"

GOTO END

:ABORT

pause

:END