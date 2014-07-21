@echo off

git describe --tags --abbrev=0 > git-tag.txt
SET /p gitversion=<git-tag.txt
del git-tag.txt

call set gitversion=%%gitversion:v=%%

cd 64

"%WIX%\bin\light.exe" ^
-nologo -sw1076 ^
-dPlatform="x64" ^
-dGitVersion=%gitversion% ^
-b gm wix\gm.wixobj ^
-b res wix\res.wixobj ^
-b perl wix\perl.wixobj ^
-b ruby wix\ruby.wixobj ^
-b jre7 wix\jre7.wixobj ^
-b conf wix\conf.wixobj ^
-b utils wix\utils.wixobj ^
-b example wix\example.wixobj ^
-b vendor\yahoo\yui wix\yui.wixobj ^
-b vendor\google\closure wix\closure.wixobj ^
wix\webmerge.wixobj ^
-ext WixBalExtension ^
-ext WixUIExtension ^
-ext WixUtilExtension ^
-o webmerge-x64.msi

cd ..
