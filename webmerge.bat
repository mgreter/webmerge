@echo off

IF NOT EXIST perl GOTO noLocalPerl

REM add local perl to global path
set PATH=%PATH%;perl\c\bin;perl\perl\site\bin;perl\perl\bin;

:noLocalPerl

perl scripts\webmerge.pl %*