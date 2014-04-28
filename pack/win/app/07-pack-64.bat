@echo off

SET PERLPATH=%CD%\64\perl

SET PATH=C:\Windows\system32

SET PATH=%PERLPATH%\perl\site\bin;%PATH%
SET PATH=%PERLPATH%\perl\bin;%PATH%
SET PATH=%PERLPATH%\c\bin;%PATH%

pushd 64

pp -B -o webmerge.exe ^
-I ../../../../lib ^
-M CSS::Sass ^
-M XML::LibXML::SAX ^
-l "%PERLPATH%/c/bin/zlib1__.dll" ^
-l "%PERLPATH%/c/bin/liblzma-5__.dll" ^
-l "%PERLPATH%/c/bin/libxml2-2__.dll" ^
-l "%PERLPATH%/c/bin/libexpat-1__.dll" ^
-l "%PERLPATH%/c/bin/libiconv-2__.dll" ^
../../../../bin/webmerge.pl

popd

pause
