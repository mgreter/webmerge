@echo off

SETLOCAL

SET TERM=dumb

SET DRIVEPWD=%~dp0

SET GMPATH=%DRIVEPWD%\..\gm
SET IMPATH=%DRIVEPWD%\..\im
SET PERLPATH=%DRIVEPWD%\..\perl
SET UTILSPATH=%DRIVEPWD%\..\utils

IF NOT EXIST "%GMPATH%" GOTO noLocalGM

REM add local gm to global path
SET PATH=%GMPATH%;%PATH%

:noLocalGM

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

perl "%DRIVEPWD%\scripts\webmerge.pl" %*

@IF ERRORLEVEL 1 GOTO errorHandling

@echo  

@sleep 1

@GOTO endHandling

:errorHandling

@pause

:endHandling

ENDLOCAL