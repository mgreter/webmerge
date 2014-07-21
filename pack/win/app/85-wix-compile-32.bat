@echo off

git describe --tags --abbrev=0 > git-tag.txt
SET /p gitversion=<git-tag.txt
del git-tag.txt

call set gitversion=%%gitversion:v=%%

cd 32

"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -dGitVersion=%gitversion% -out wix\gm.wixobj wix\gm.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -dGitVersion=%gitversion% -out wix\perl.wixobj wix\perl.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -dGitVersion=%gitversion% -out wix\ruby.wixobj wix\ruby.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -dGitVersion=%gitversion% -out wix\jre7.wixobj wix\jre7.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -dGitVersion=%gitversion% -out wix\utils.wixobj wix\utils.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -dGitVersion=%gitversion% -out wix\res.wixobj wix\res.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -dGitVersion=%gitversion% -out wix\conf.wixobj wix\conf.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -dGitVersion=%gitversion% -out wix\yui.wixobj wix\yui.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -dGitVersion=%gitversion% -out wix\closure.wixobj wix\closure.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -dGitVersion=%gitversion% -out wix\example.wixobj wix\example.wxs

"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -ext WixUtilExtension -dGitVersion=%gitversion% -out wix\webmerge.wixobj ..\wix\webmerge.wxs

cd ..
