Webmerge
========
Asset Manager for Front End Development (JS, CSS, Images)

Features
========
- Merge, join and optimize CSS and JavaScript files
- Optimize images with external tools (in parallel jobs)
- Create spritesets by simply annotating your css stylesheets
- Can handle sprites optimized for high resolution displays (retina)
- Optimize text files by removing UTF8 BOM and trailing whitespaces
- Commits all file changes only after a successfull merge ("atomic")
- File watcher to recompile automatically when a source file has changed

To Do
=====
- Integrate a SASS/LESS processor
- Implement @license header handling
- Maybe add support for ImageMagick too
- Finalize API for spritesets generator
- Improve path handling for js dev targets
- Normalize web_url/path and import/exportURL
- Make writes/reads on same atomic file transparent

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
to find a package for Graphics-Magick with your distribution. All
perl modules are perl code only and could also be downloaded from
www.cpan.org and then be put into the script/modules directory.

Installing Perl Modules
=======================
    perl -MCPAN -e "install CSS::Minifier"
    perl -MCPAN -e "install JavaScript::Minifier"
    perl -MCPAN -e "install Data::Dump::PHP"
    perl -MCPAN -e "install File::MimeInfo::Simple"
    # modules are only needed for watcher
    perl -MCPAN -e "install IPC::Run3"
    perl -MCPAN -e "install Filesys::Notify::Simple"

Installing on Gentoo Linux
==========================
    # maybe review the use flags
    USE="perl png jpeg q16" \
    emerge -u media-gfx/graphicsmagick
    # install needed perl modules
    emerge -u dev-perl/CSS-Minifier
    emerge -u dev-perl/JavaScript-Minifier
    # Data::Dump::PHP has no ebuild yet
    perl -MCPAN -e "install Data::Dump::PHP"
    perl -MCPAN -e "install File::MimeInfo::Simple"
    # modules are only needed for watcher
    emerge -u dev-perl/IPC-Run3
    emerge -u dev-perl/Filesys-Notify-Simple

Installing Closure Compiler
===========================
Go into the scripts/google/closure directory and execute the update script.
You will need wget and unzip accessible. On windows I suggest you install
UnxUtils into an accessible path (like c:\windows or add a directory to your
global path environment variable). You can also download the compiler manually
and extract it to the directory.

- http://sourceforge.net/projects/unxutils/
- http://closure-compiler.googlecode.com/files/compiler-latest.zip

Other external optimizers
=========================
- http://jpegclub.org/jpegtran/ (jpegtran)
- http://www.lcdf.org/gifsicle/ (gifsicle)
- http://optipng.sourceforge.net/ (optipng)
- http://advancemame.sourceforge.net/comp-download.html (advdef & advpng)

Using Webmerge
==============
Documentation not yet done. See example directory for hints. Call
webmerge script with --help to get information about the available
command line options.

Portable version for windows
============================
I created some archives with pre packed binaries for perl and
GraphicsMagick. You may download them from my server. I'm not
sure if this is 100% legal, if not please contact me and I will
remove these downloads.

- http://webmerge.ocbnet.ch/portable/webmerge-gm-x32.exe
- http://webmerge.ocbnet.ch/portable/webmerge-perl-x32.exe
- http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe
- http://webmerge.ocbnet.ch/portable/webmerge-gm-x64.exe
- http://webmerge.ocbnet.ch/portable/webmerge-perl-x64.exe

Download the appropriate versions (either x32 or x64) and
extract the archives beside the main webmerge directory.
You should finally get this folder structure:
__tools\gm__, __tools\perl__, __tools\webmerge__. Then you
can use the run script __tools\webmerge\webmerge.bat__


Demo Examples
=============
- http://webmerge.ocbnet.ch/webmerge/example/embeder/
- http://webmerge.ocbnet.ch/webmerge/example/sprites/fam/
- http://webmerge.ocbnet.ch/webmerge/example/sprites/hires/

Command Line Options
====================
    -f, --configfile    main xml configuration
    -d, --doctype      how to render includes [html|xhtml|html5]
    -j, --jobs        number of jobs (commands) to run simultaneously

    -w, --watchdog     start the watchdog process (quit with ctrl+c)

    --webroot         webroot directory to render absolute urls
    --import-css       inline imported css files into stylesheet
    --absoluteurls     export urls as absolute urls (from webroot)

    --referer         optional referer url for external downloads
    --inlinedataexts    file extensions to inline (comma separated)
    --inlinedatamax    maximum file sizes to inline into stylesheets

    --crc-check        run crc check before exiting
    --crc-file        write crc file beside generated files
    --crc-comment      append crc comment into generated files

    --fingerprint      add fingerprints to includes (--fp)
    --fingerprint-dev   for dev context [query|directory|file] (--fp-dev)
    --fingerprint-live  for live context [query|directory|file] (--fp-live)

    --txt-type        text type [nix|mac|win]
    --txt-remove-bom    remove superfluous utf boms
    --txt-normalize-eol normalize line endings to given type
    --txt-trim-trailing trim trailing whitespace in text files

    --headtmpl        text to prepend to generated files
    --jsdeferer        javascript loader for defered loading
    --tmpl-embed-php    embeder template for php embeder generator

    -p, --prepare      enable/disable prepare steps
    -o, --optimize     enable/disable optimize steps
    -m, --merge        enable/disable merge steps
    -i, --headinc      enable/disable headinc steps
    -e, --embeder      enable/disable embeder steps

    --dev            enable/disable dev targets
    --join            enable/disable join targets
    --minify          enable/disable minify targets
    --compile         enable/disable compile targets
    --license         enable/disable license targets

    --optimize-txt     enable/disable optimizer for text files (--txt)
    --optimize-jpg     enable/disable optimizer for jpg images (--jpg)
    --optimize-gif     enable/disable optimizer for gif images (--gif)
    --optimize-png     enable/disable optimizer for png images (--png)
    --optimize-mng     enable/disable optimizer for mng images (--mng)
    --optimize-zip     enable/disable optimizer for zip archives (--zip)
    --optimize-gz      enable/disable optimizer for gz archive files (--gz)

    -dbg, --debug      enable/disable debug mode

    --man            full documentation
    --opts            list command line options
    -?, --help        brief help message with options


Credits
=======
Developement was mostly done while working at http://www.rtp.ch.
Thanks a lot to them for allowing me to publish this utility!
