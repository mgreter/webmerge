@echo off

cd wix
cd RefreshEnvAction

echo try to load command prompt for visual studio 11 (VS2012 x86)
call "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86

msbuild /p:Configuration=debug
msbuild /p:Configuration=release

cd ..
cd ..
