@echo off

SET version=%~1
REM git tag or branch
if "%version%" == "" SET version=master

echo Installing webmerge 64-bit portable (%version%)

:CheckOS
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT
IF EXIST "%PROGRAMFILES%" SET installdir=%PROGRAMFILES%\ocbnet
IF EXIST "%ProgramW6432%" SET installdir=%ProgramW6432%\ocbnet
GOTO GotOS

:32BIT
echo "Cannot install 64bit software on 32bit system"
GOTO ABORT

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

if not exist files\64 mkdir files\64

cd files\64

..\utils\wget --no-check-certificate -c https://github.com/mgreter/webmerge/archive/%version%.zip -O "%version%.zip"
for %%R in ("%version%.zip") do if %%~zR lss 1 del "%version%.zip"
if not exist "%version%.zip" echo error downloading archive && pause && exit
..\utils\wget "http://dl.google.com/closure-compiler/compiler-latest.zip"
if not exist "compiler-latest.zip" echo error downloading archive && pause && exit
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-gm-x64.exe
if not exist "webmerge-gm-x64.exe" echo error downloading archive && pause && exit
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-perl-x64.exe
if not exist "webmerge-perl-x64.exe" echo error downloading archive && pause && exit
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe
if not exist "webmerge-utils-x32.exe" echo error downloading archive && pause && exit
..\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x64.exe
if not exist "webmerge-ruby-sass-x64.exe" echo error downloading archive && pause && exit

if not exist "%installdir%" mkdir "%installdir%"

cd "%installdir%"

"%~dp0\files\64\webmerge-gm-x64.exe" -y
"%~dp0\files\64\webmerge-perl-x64.exe" -y
"%~dp0\files\64\webmerge-utils-x32.exe" -y
"%~dp0\files\64\webmerge-ruby-sass-x64.exe" -y

if exist webmerge rmdir webmerge /s /q
"%~dp0\files\utils\unzip" -o "%~dp0\files\64\%version%.zip"
if "%version:~0,1%" == "v" set version=%version:~1%
rename "webmerge-%version%" webmerge

"%~dp0\files\utils\unzip" -o "%~dp0\files\64\compiler-latest.zip" -d webmerge\scripts\google\closure

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

copy /Y "%~dp0\uninstall-x64.bat" "%installdir%\uninstall-webmerge.bat"
if not %ERRORLEVEL%==0 set ABORT=1

echo https://github.com/mgreter/webmerge/archive/%version%.zip (64bit) > "%installdir%\webmerge-version.txt"

echo Finished installing webmerge 64-bit portable
echo Installed %version% at "%installdir%"

if "%ABORT%" == "1" GOTO ABORT

GOTO END

:ABORT

pause

:END
