@echo off

echo Uninstalling webmerge 32-bit portable

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

echo Uninstalling at "%installdir%"

pushd "%CD%"
CD /D "%~dp0"

echo Remove old global paths (ignore warnings)

"%installdir%\installer\files\utils\pathed" -r "%PROGRAMFILES%\webmerge\webmerge"
"%installdir%\installer\files\utils\pathed" -r "%PROGRAMFILES(X86)%\webmerge\webmerge"

echo Remove Webmerge from "%installdir%"

if exist "%installdir%\gm" rmdir "%installdir%\gm" /S /Q
if exist "%installdir%\ruby" rmdir "%installdir%\ruby" /S /Q
if exist "%installdir%\perl" rmdir "%installdir%\perl" /S /Q
if exist "%installdir%\utils" rmdir "%installdir%\utils" /S /Q
if exist "%installdir%\webmerge" rmdir "%installdir%\webmerge" /S /Q

if exist "%installdir%\webmerge-version.txt" del "%installdir%\webmerge-version.txt" /Q
if exist "%installdir%\uninstall-webmerge.bat" del "%installdir%\uninstall-webmerge.bat" /Q

if exist "%installdir%" rmdir "%installdir%" /Q

GOTO END

:ABORT

pause

:END
