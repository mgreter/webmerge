@echo off

SET PERLPATH=%CD%\32\perl

SET PATH=C:\Windows\system32

SET PATH=%PERLPATH%\perl\site\bin;%PATH%
SET PATH=%PERLPATH%\perl\bin;%PATH%
SET PATH=%PERLPATH%\c\bin;%PATH%

pushd 32

pp -B -o webmerge.exe ^
-I ../../scripts/modules ^
-M CSS::Sass ^
-M XML::LibXML::SAX ^
-l "%PERLPATH%/c/bin/zlib1_.dll" ^
-l "%PERLPATH%/c/bin/liblzma-5_.dll" ^
-l "%PERLPATH%/c/bin/libxml2-2_.dll" ^
-l "%PERLPATH%/c/bin/libiconv-2_.dll" ^
../../scripts/webmerge.pl

popd

pause