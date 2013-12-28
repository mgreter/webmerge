@echo off

call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\embedder.conf.xml" %*

start "" "http://localhost:8080"

call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\embedder.conf.xml" %* --webserver

REM call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\embedder.conf.xml" %* --watchdog --dbg
