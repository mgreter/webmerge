mkdir 32
mkdir 64

cd 32

..\..\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-gm-x32.exe
..\..\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-perl-x32.exe
..\..\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x32.exe
..\..\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe

cd ..

cd 64

..\..\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-gm-x64.exe
..\..\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-jre7-x64.exe
..\..\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-perl-x64.exe
..\..\files\utils\wget -c http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x64.exe

cd ..
