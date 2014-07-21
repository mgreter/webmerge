@echo off

call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\sprites.conf.xml" --optimize-png fam hires %*

REM start "" "http://localhost:8000/fam"
REM start "" "http://localhost:8000/hires"

REM call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\sprites.conf.xml" --optimize-png -png fam hires %* --webserver

REM call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\sprites.conf.xml" --optimize -png fam hires %* --watchdog --dbg
