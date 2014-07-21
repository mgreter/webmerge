@echo off

pushd "%~dp0"

REM you need to have the unix utils installed
REM http://unxutils.sourceforge.net/UnxUtils.zip
REM or download/unzip the closure compiler manually

wget "https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar" -o yuicompressor.jar

popd