@echo off

SET arch=%~1

echo %arch%

call 00-fetch-%arch%
call 01-prepare-%arch%
call 06-icon-%arch%
call 07-pack-%arch%

call 80-fetch-%arch%
call 82-wix-prepare-%arch%
call 83-wix-collect-%arch%
call 85-wix-compile-%arch%
call 89-wix-link-%arch%

dir %arch%\*.msi