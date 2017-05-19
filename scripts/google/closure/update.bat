@echo off

pushd "%~dp0"

REM you need to have the unix utils installed
REM http://unxutils.sourceforge.net/UnxUtils.zip
REM or download/unzip the closure compiler manually

wget "http://dl.google.com/closure-compiler/compiler-latest.zip"
unzip -o "compiler-latest.zip" && del "compiler-latest.zip"
if exist closure-compiler-*.jar (
	if exist compiler.jar del compiler.jar
	rename closure-compiler-*.jar compiler.jar
)

popd