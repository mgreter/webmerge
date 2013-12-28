@echo off

call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\sprites.conf.xml" -o -png fam hires %*

start "" "http://localhost:8080/fam"
start "" "http://localhost:8080/hires"

call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\sprites.conf.xml" -o -png fam hires %* --webserver

REM call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\sprites.conf.xml" -o -png fam hires %* --watchdog --dbg
