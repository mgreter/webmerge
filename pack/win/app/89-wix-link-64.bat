@echo off

git describe --tags --abbrev=0 > git-tag.txt
SET /p gitversion=<git-tag.txt
del git-tag.txt

call set gitversion=%%gitversion:v=%%

cd 64

"%WIX%\bin\light.exe" -nologo -b vendor\yahoo\yui -b vendor\google\closure -b example -b res -b conf -b utils -b gm -b perl -b ruby -b jre7 -ext WixBalExtension -ext WixUIExtension -ext WixUtilExtension -sw1076 -dGitVersion=%gitversion% -o webmerge-x64.msi ^
                       wix\gm.wixobj wix\perl.wixobj wix\ruby.wixobj wix\jre7.wixobj wix\utils.wixobj wix\res.wixobj wix\conf.wixobj wix\yui.wixobj wix\closure.wixobj wix\example.wixobj wix\webmerge.wixobj

cd ..
