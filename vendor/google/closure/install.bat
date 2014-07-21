@echo off

IF NOT EXIST "%~dp0/compiler.jar" CALL "%~dp0/update.bat"
