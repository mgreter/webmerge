Webmerge
========
Asset Manager for Front End Development (JS, CSS, Images)

Features
========
- Merge, join and minify CSS and JavaScript files
- Optimize images with external tools (in parallel)
- Create spritesets by annotating your css stylesheets
- Can handle sprites optimized for high resolution displays
- Optimize text files by removing UTF8 BOM and trailing whitespace
- Does not overwrite any files if a merge is not completely successfull
- File watcher to recompile if a source file has changed

To Do
=====
- Finish spriteset feature
- Integrate a SASS processor
- Add additional Optimizers (pngcrush, advzip, advmng)


Installing on Windows
=====================
You need to install Strawberry Perl and GraphicsMagick:
- http://strawberryperl.com/releases.html
- ftp://ftp.graphicsmagick.org/pub/GraphicsMagick/windows/

Tested versions:
- strawberry-perl-5.14.4.1-64bit.msi
- GraphicsMagick-1.3.18-Q16-win64-dll.exe

The latest Graphics Magick may not support the latest Strawberry Perl!

Installing on Linux/Mac
=======================
Perl should already be installed and ready. You should be able
to find a package for Graphics-Magick with your distribution.

Installing Perl Modules
=======================
    perl -MCPAN -e "install File::MimeInfo"
    perl -MCPAN -e "install CSS::Minifier"
    perl -MCPAN -e "install JavaScript::Minifier"
    perl -MCPAN -e "install Data::Dump::PHP"
    # modules are only needed for watcher
	perl -MCPAN -e "install IPC::Run3"
    perl -MCPAN -e "install Filesys::Notify::Simple"

Installing on Gentoo Linux
==========================
    # maybe review the use flags
    USE="perl png jpeg q16" \
    emerge -u media-gfx/graphicsmagick
	# install needed perl modules
    emerge -u dev-perl/File-MimeInfo
    emerge -u dev-perl/CSS-Minifier
    emerge -u dev-perl/JavaScript-Minifier
    # Data::Dump::PHP has no ebuild yet
    perl -MCPAN -e "install Data::Dump::PHP"
    # modules are only needed for watcher
    emerge -u dev-perl/IPC-Run3
    emerge -u dev-perl/Filesys-Notify-Simple

Other external optimizers
=========================
- http://jpegclub.org/jpegtran/ (jpegtran)
- http://www.lcdf.org/gifsicle/ (gifsicle)
- http://optipng.sourceforge.net/ (optipng)
- http://advancemame.sourceforge.net/comp-readme.html (advdef & advpng)

Using Webmerge
==============
Documentation not yet done. See example directory for hints.

Credits
=======
Developement was mostly done while working at http://www.rtp.ch.
Thanks a lot to them for allowing me to publish this utility!
