@echo off

SET version=%~1
REM git tag or branch
if "%version%" == "" SET version=master

echo Installing webmerge 32-bit portable (%version%)

:CheckOS
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT
SET installdir=%PROGRAMFILES(X86)%\ocbnet
GOTO GotOS

:32BIT
SET installdir=%PROGRAMFILES%\ocbnet
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

IF EXIST "%installdir%\uninstall-webmerge.bat" call "%installdir%\uninstall-webmerge.bat"

:--------------------------------------

echo Installing into "%installdir%"

pushd "%CD%"
CD /D "%~dp0"

if not exist files\32 mkdir files\32

cd files\32

..\utils\wget --no-check-certificate -c https://github.com/mgreter/webmerge/archive/%version%.zip -O "%version%.zip"
for %%R in ("%version%.zip") do if %%~zR lss 1 del "%version%.zip"
if not exist "%version%.zip" echo error downloading archive && pause && exit
..\utils\wget "http://dl.google.com/closure-compiler/compiler-latest.zip"
if not exist "compiler-latest.zip" echo error downloading archive && pause && exit
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-gm-x32.exe
if not exist "webmerge-gm-x32.exe" echo error downloading archive && pause && exit
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-perl-x32.exe
if not exist "webmerge-perl-x32.exe" echo error downloading archive && pause && exit
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe
if not exist "webmerge-utils-x32.exe" echo error downloading archive && pause && exit
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x32.exe
if not exist "webmerge-ruby-sass-x32.exe" echo error downloading archive && pause && exit

if not exist "%installdir%" mkdir "%installdir%"

cd "%installdir%"

"%~dp0\files\32\webmerge-gm-x32.exe" -y
"%~dp0\files\32\webmerge-perl-x32.exe" -y
"%~dp0\files\32\webmerge-utils-x32.exe" -y
"%~dp0\files\32\webmerge-ruby-sass-x32.exe" -y

if exist webmerge rmdir webmerge /s /q
"%~dp0\files\utils\unzip" -o "%~dp0\files\32\%version%.zip"
if "%version:~0,1%" == "v" set version=%version:~1%
rename "webmerge-%version%" webmerge

"%~dp0\files\utils\unzip" -o "%~dp0\files\32\compiler-latest.zip" -d webmerge\scripts\google\closure

echo Updating file permissions

cacls "%installdir%\webmerge\res" /t /e /g Everyone:f
if not %ERRORLEVEL%==0 set ABORT=1
cacls "%installdir%\webmerge\conf" /t /e /g Everyone:f
if not %ERRORLEVEL%==0 set ABORT=1
cacls "%installdir%\webmerge\example" /t /e /g Everyone:f
if not %ERRORLEVEL%==0 set ABORT=1

echo Remove old global paths (ignore warnings)

"%~dp0\files\utils\pathed" -r "%installdir%\webmerge"
"%~dp0\files\utils\pathed" -r "%PROGRAMFILES%\ocbnet\webmerge"
"%~dp0\files\utils\pathed" -r "%PROGRAMFILES(X86)%\ocbnet\webmerge"

echo Add global path "%installdir%\webmerge"

"%~dp0\files\utils\pathed" -a "%installdir%\webmerge"
if not %ERRORLEVEL%==0 set ABORT=1

echo Copy uninstall file into "%installdir%"

copy /Y "%~dp0\uninstall-x32.bat" "%installdir%\uninstall-webmerge.bat"
if not %ERRORLEVEL%==0 set ABORT=1

echo https://github.com/mgreter/webmerge/archive/%version%.zip (32bit) > "%installdir%\webmerge-version.txt"

echo Finished installing webmerge 32-bit portable
echo Installed %version% at "%installdir%"

if "%ABORT%" == "1" GOTO ABORT

GOTO END

:ABORT

pause

:END
