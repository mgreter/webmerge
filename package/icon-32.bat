@echo off

SET PERLPATH=%CD%\32\perl

SET PATH=C:\Windows\system32

SET PATH=%PERLPATH%\perl\site\bin;%PATH%
SET PATH=%PERLPATH%\perl\bin;%PATH%
SET PATH=%PERLPATH%\c\bin;%PATH%

SET PERL_DIR=%CD%\32\perl\perl
REM you will need to copy this over from data/.cpanm
SET PAR_PACKER_SRC=%CD%\32\perl\cpan\build\PAR-Packer-1.017

copy /Y ..\res\webmerge.ico "%PAR_PACKER_SRC%\myldr\winres\pp.ico"

pushd "%PAR_PACKER_SRC%\myldr\"

del ppresource.coff
perl Makefile.PL
dmake boot.exe
dmake Static.pm

popd

attrib -R "%PERL_DIR%\site\lib\PAR\StrippedPARL\Static.pm"
copy /Y "%PAR_PACKER_SRC%\myldr\Static.pm" "%PERL_DIR%\site\lib\PAR\StrippedPARL\Static.pm"

pause
