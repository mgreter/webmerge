@echo off

SET OLDPATH=%PATH%
SET PERLPATH=%CD%\32\perl
SET PATH=C:\Windows\system32

SET PATH=%PERLPATH%\perl\site\bin;%PATH%
SET PATH=%PERLPATH%\perl\bin;%PATH%
SET PATH=%PERLPATH%\c\bin;%PATH%

cd 32

call pp -B -o webmerge.exe ^
-I ../../../../lib ^
-M File::chdir ^
-M CSS::Sass ^
-M Encode::CN ^
-M Encode::JP ^
-M Encode::KR ^
-M Encode::TW ^
-M Encode::Byte ^
-M Encode::Unicode ^
-M XML::LibXML::SAX ^
-M OCBNET::Webmerge::Plugin::JS::Minify ^
-M OCBNET::Webmerge::Plugin::JS::Compile ^
-M OCBNET::Webmerge::Plugin::JS::License ^
-M OCBNET::Webmerge::Plugin::JS::NodeMinify ^
-M OCBNET::Webmerge::Plugin::CSS::Minify ^
-M OCBNET::Webmerge::Plugin::CSS::Compile ^
-M OCBNET::Webmerge::Plugin::CSS::SASS ^
-M OCBNET::Webmerge::Plugin::CSS::SCSS ^
-M OCBNET::Webmerge::Plugin::CSS::Lint ^
-M OCBNET::Webmerge::Plugin::CSS::License ^
-M OCBNET::Webmerge::Plugin::CSS::InlineData ^
-M OCBNET::Webmerge::Plugin::CSS::Spritesets ^
-M OCBNET::Webmerge::XML::File::Input::JS ^
-M OCBNET::Webmerge::XML::File::Output::JS ^
-M OCBNET::Webmerge::XML::File::Input::CSS ^
-M OCBNET::Webmerge::XML::File::Output::CSS ^
-l "%PERLPATH%/c/bin/zlib1_.dll" ^
-l "%PERLPATH%/c/bin/liblzma-5_.dll" ^
-l "%PERLPATH%/c/bin/libxml2-2_.dll" ^
-l "%PERLPATH%/c/bin/libexpat-1_.dll" ^
-l "%PERLPATH%/c/bin/libiconv-2_.dll" ^
../../../../bin/webmerge.pl

cd ..

SET PATH=%OLDPATH%
echo %PATH%