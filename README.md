WebMerge
========

Asset Manager for Front End Development (JS, CSS, Images)

- Merge, join and minify CSS and JavaScript files
- Optimize images with external tools (in parallel)

Installing on Windows
=====================

You need to install Strawberry Perl and GraphicsMagick:
- http://strawberryperl.com/releases.html
- ftp://ftp.graphicsmagick.org/pub/GraphicsMagick/windows/

Tested versions:
- strawberry-perl-5.14.4.1-64bit.msi
- GraphicsMagick-1.3.18-Q16-win64-dll.exe

* The latest Graphics Magick may not support the latest Strawberry Perl!

Installing Perl Modules
=======================
perl -MCPAN -e "install CSS::Minifier"
perl -MCPAN -e "install JavaScript::Minifier"
perl -MCPAN -e "install Data::Dump::PHP"
perl -MCPAN -e "install File::MimeInfo"

Credits
=======

Developement was mostly done while working at http://www.rtp.ch.
Thanks a lot to them for allowing me to publish this utility!
