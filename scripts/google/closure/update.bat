@echo off

cd "%~dp0"

REM You need to have the unix utils installed
REM http://unxutils.sourceforge.net/UnxUtils.zip

wget "http://dl.google.com/closure-compiler/compiler-latest.zip"
unzip -o "compiler-latest.zip" && del "compiler-latest.zip"