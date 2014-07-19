@echo off

cd 32

if not exist wix mkdir wix

"%WIX%\bin\heat.exe" dir ".\gm" -nologo -cg gm -nologo -gg -scom -sreg -ke -dr INSTALLDIR -template fragment -out wix\gm.wxs -platform x86
"%WIX%\bin\heat.exe" dir ".\perl" -nologo -cg perl -nologo -gg -scom -sreg -ke -dr INSTALLDIR -template fragment -out wix\perl.wxs -platform x86
"%WIX%\bin\heat.exe" dir ".\ruby" -nologo -cg ruby -nologo -gg -scom -sreg -ke -dr INSTALLDIR -template fragment -out wix\ruby.wxs -platform x86
"%WIX%\bin\heat.exe" dir ".\jre7" -nologo -cg jre7 -nologo -gg -scom -sreg -ke -dr INSTALLDIR -template fragment -out wix\jre7.wxs -platform x86
"%WIX%\bin\heat.exe" dir ".\utils" -nologo -cg utils -nologo -gg -scom -sreg -ke -dr INSTALLDIR -template fragment -out wix\utils.wxs -platform x86

"%WIX%\bin\heat.exe" dir ".\res" -nologo -cg res -nologo -gg -scom -sreg -ke -dr INSTALLDIR -template fragment -out wix\res.wxs -platform x86
"%WIX%\bin\heat.exe" dir ".\conf" -nologo -cg conf -nologo -gg -scom -sreg -ke -dr INSTALLDIR -template fragment -out wix\conf.wxs -platform x86
"%WIX%\bin\heat.exe" dir ".\example" -nologo -cg example -nologo -gg -scom -sreg -ke -dr INSTALLDIR -template fragment -out wix\example.wxs -platform x86
"%WIX%\bin\heat.exe" dir ".\vendor\yahoo\yui" -nologo -cg yui -nologo -gg -scom -sreg -ke -dr VendorYahoo -template fragment -out wix\yui.wxs -platform x86
"%WIX%\bin\heat.exe" dir ".\vendor\google\closure" -nologo -cg closure -nologo -gg -scom -sreg -ke -dr VendorGoogle -template fragment -out wix\closure.wxs -platform x86

cd ..
