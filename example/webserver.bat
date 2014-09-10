@echo off

start "" "http://localhost:4000"

call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\webserver.conf.xml" --webserver
