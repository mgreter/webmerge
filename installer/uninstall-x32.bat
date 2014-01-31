@echo off

echo Uninstalling webmerge 32-bit portable

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

echo Uninstalling at "%installdir%"

pushd "%CD%"
CD /D "%~dp0"

echo Remove old global paths (ignore warnings)

"%installdir%\installer\files\utils\pathed" -r "%PROGRAMFILES%\webmerge\webmerge"
"%installdir%\installer\files\utils\pathed" -r "%PROGRAMFILES(X86)%\webmerge\webmerge"

echo Remove Webmerge from "%installdir%\ocbnet"

if exist "%installdir%\ocbnet\webmerge" rmdir "%installdir%\ocbnet\webmerge" /s /q
if exist "%installdir%\ocbnet\utils" rmdir "%installdir%\ocbnet\utils" /s /q
if exist "%installdir%\ocbnet\ruby" rmdir "%installdir%\ocbnet\ruby" /s /q
if exist "%installdir%\ocbnet\perl" rmdir "%installdir%\ocbnet\perl" /s /q
if exist "%installdir%\ocbnet\gm" rmdir "%installdir%\ocbnet\gm" /s /q

if exist "%installdir%\ocbnet\uninstall-webmerge.bat" del /Q "%installdir%\ocbnet\uninstall-webmerge.bat"

if exist "%installdir%\ocbnet" rmdir "%installdir%\ocbnet" /q

GOTO END

:ABORT

pause

:END
