@echo off

echo Uninstalling webmerge 32-bit portable

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

if exist 32 rmdir 32 /s /q

echo Remove old global paths (ignore warnings)

files\utils\pathed -r "%CD%\32\webmerge"
files\utils\pathed -r "%CD%\64\webmerge"

REM cscript files\vbs\DelFromSystemPath.vbs //Nologo "%CD%\32\webmerge"
REM cscript files\vbs\DelFromSystemPath.vbs //Nologo "%CD%\64\webmerge"
