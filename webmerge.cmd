@echo off

SETLOCAL

SET EXEC=%~0
SET TERM=dumb

REM check if not called global
IF EXIST %0 GOTO processExec

REM find the exec within paths
REM http://stackoverflow.com/a/12570623
FOR %%P IN (%PATHEXT%) DO (
	FOR %%I IN (%~0 %~0%%P) DO (
		if exist "%%~$PATH:I" (
			SET EXEC=%%~$PATH:I
			GOTO processExec
		)
	)
)

:processExec

REM split exec into parts
For %%F IN ("%EXEC%") do (
	Set FOLDER=%%~dpF
	Set NAME=%%~nxF
)

SET GMPATH=%FOLDER%\..\gm
SET IMPATH=%FOLDER%\..\im
SET PERLPATH=%FOLDER%\..\perl
SET UTILSPATH=%FOLDER%\..\utils

:installLocals

IF NOT EXIST "%IMPATH%" GOTO noLocalIM

REM add local im to global path
SET PATH=%IMPATH%;%PATH%

:noLocalIM

IF NOT EXIST "%UTILSPATH%" GOTO noLocalUtils

REM add local utils to global path
SET PATH=%UTILSPATH%;%PATH%

:noLocalUtils

IF NOT EXIST "%PERLPATH%" GOTO noLocalPerl

REM add local perl to global path
SET PATH=%PERLPATH%\perl\site\bin;%PATH%
SET PATH=%PERLPATH%\perl\bin;%PATH%
SET PATH=%PERLPATH%\c\bin;%PATH%

:noLocalPerl

perl "%FOLDER%\scripts\webmerge.pl" %*

@IF ERRORLEVEL 1 GOTO errorHandling

@echo 

@sleep 1

@GOTO endHandling

:errorHandling

@pause

:endHandling

ENDLOCAL