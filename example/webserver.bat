@echo off

start "" "http://localhost:8000"

call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\webserver.conf.xml" --webserver
