@echo off

cd 32

"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -out wix\gm.wixobj wix\gm.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -out wix\perl.wixobj wix\perl.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -out wix\ruby.wixobj wix\ruby.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -out wix\jre7.wixobj wix\jre7.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -out wix\utils.wixobj wix\utils.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -out wix\res.wixobj wix\res.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -out wix\conf.wixobj wix\conf.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -out wix\yui.wixobj wix\yui.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -out wix\closure.wixobj wix\closure.wxs
"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -out wix\example.wixobj wix\example.wxs

"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -out wix\webmerge.wixobj ..\wix\webmerge.wxs

cd ..

pause