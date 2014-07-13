@echo off

call "%~dp0\..\webmerge.bat" -f "%~dp0\conf\webserver.conf.xml" --webdump --dumproot=webexport
