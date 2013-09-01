@echo off

SETLOCAL

SET GMPATH=..\gm
SET IMPATH=..\im
SET PERLPATH=..\perl

IF NOT EXIST %GMPATH% GOTO noLocalGM

REM add local gm to global path
SET PATH=%PATH%;%GMPATH%

:noLocalGM

IF NOT EXIST %IMPATH% GOTO noLocalIM

REM add local im to global path
SET PATH=%PATH%;%IMPATH%

:noLocalIM

IF NOT EXIST %PERLPATH% GOTO noLocalPerl

REM add local perl to global path
SET PATH=%PATH%;%PERLPATH%\c\bin
SET PATH=%PATH%;%PERLPATH%\perl\site\bin
SET PATH=%PATH%;%PERLPATH%\perl\bin

:noLocalPerl

perl scripts\webmerge.pl %*

ENDLOCAL