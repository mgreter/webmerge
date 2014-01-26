Webmerge
========
Asset Manager for Front End Development (JS, CSS, Images)

Features
========
- Merge, join and optimize SCSS, CSS and JavaScript files
- Compiles scss/sass either via libsass or ruby sass (external)
- Optimize images etc. with external tools (in parallel jobs)
- Create spritesets by simply annotating your css stylesheets
- Can handle sprites optimized for high resolution displays (retina)
- Includes with a small webserver to test drive your prototypes (alpha)
- Optimize text files by removing UTF8 BOM and trailing whitespaces
- Commits all file changes only after a successfull merge ("atomic")
- File watcher to recompile automatically when a source file has changed
- Create checksums and embedder code to auto embed the best assets for UA

To Do
=====
- Write documentation
- Add clean and test targets
- Prepare code for v1.0.0 release
- Handle source maps for css and js
- Implement @license header handling
- Test more edge cases (specially css parser)
- Invoke processors according to file extensions

More ideas
==========
- Allow to merge multiple spritesets
- Means we'll have to re-use same src
- Add CoffeeScript and LESS processor
- Maybe add support for ImageMagick too
- Add smart locks to ensure parallel execution
- Implement parallel workers for unrelated blocks
- Put more usefull information to the console
- i.e. files imported, files created, time needed ...

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
    perl -MCPAN -e "install Data::Dump::PHP"
    perl -MCPAN -e "install File::MimeInfo"
    # modules are only needed as "fallbacks"
    perl -MCPAN -e "install CSS::Minifier"
    perl -MCPAN -e "install JavaScript::Minifier"
    # module is only needed if you use scss processor
    perl -MCPAN -e "install CSS::Sass"
    # modules are only needed for watcher
    perl -MCPAN -e "install IPC::Run3"
    perl -MCPAN -e "install Filesys::Notify::Simple"

Installing on Gentoo Linux
==========================
    # maybe review the use flags
    USE="perl png jpeg q16" \
    emerge -u media-gfx/graphicsmagick
    # Data::Dump::PHP has no ebuild yet
    perl -MCPAN -e "install Data::Dump::PHP"
    # install needed perl modules
    emerge -u dev-perl/File-MimeInfo
    # modules are only needed as "fallbacks"
    emerge -u dev-perl/CSS-Minifier
    emerge -u dev-perl/JavaScript-Minifier
    # module is only needed if you use scss processor
    perl -MCPAN -e "install CSS::Sass"
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
- http://dl.google.com/closure-compiler/compiler-latest.zip

Other external optimizers
=========================
- http://jpegclub.org/jpegtran/ (jpegtran)
- http://www.lcdf.org/gifsicle/ (gifsicle)
- http://optipng.sourceforge.net/ (optipng)
- http://freecode.com/projects/jpegoptim (jpegoptim)
- http://advancemame.sourceforge.net/comp-download.html (advdef & advpng)

Using Webmerge
==============
Documentation not yet done. See example directory for hints. Call
webmerge script with --help to get information about the available
command line options.

Optimization levels
===================
You can finetune the level by which we try to optimize things. This mostly
defines how the external optimizers will be invoked. Webmerge tries to use
a range of 1 - 6, but higher levels can also be set. Altough level 6 should
already be close to the maximum optimization one can achieve. But certain
programs allow for much insaner optimization levels. A level of 0 means
the optimizer will not even run at all.

| level    |  0 |  1 |  2 |  3 |  4 |  5 |  6 |  7 |  8 |  9 |  10 |  11 |  12 |
| --------:| --:| --:| --:| --:| --:| --:| --:| --:| --:| --:| ---:| ---:| ---:|
|  advcomp |  - |  1 |  2 |  2 |  3 |  3 |  4 |  4 |  4 |  4 |   4 |  4 |   4 |
|  optipng |  - |  1 |  2 |  3 |  3 |  4 |  5 |  5 |  6 |  7 |   8 |  8 |   9 |
| gifsicle |  - |  1 |  2 |  2 |  2 |  3 |  3 |  3 |  3 |  3 |   3 |  3 |   3 |

Portable version for windows
============================
I created some archives with pre packed binaries for perl and
GraphicsMagick. You may download them from my server. I'm not
sure if this is 100% legal, if not please contact me and I will
remove these downloads. These are 7zip self extracting archives
(sfx) and will extract the files into a subfolder (perl, utils and gm).
You can also use the x32 utils on x64 systems.

- http://webmerge.ocbnet.ch/portable/webmerge-gm-x32.exe
- http://webmerge.ocbnet.ch/portable/webmerge-perl-x32.exe
- http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe
- http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x32.exe
- http://webmerge.ocbnet.ch/portable/webmerge-gm-x64.exe
- http://webmerge.ocbnet.ch/portable/webmerge-perl-x64.exe
- http://webmerge.ocbnet.ch/portable/webmerge-utils-x32.exe
- http://webmerge.ocbnet.ch/portable/webmerge-ruby-sass-x64.exe

Download the appropriate versions (either x32 or x64) and
extract the archives beside the main webmerge directory.
You should finally get this folder structure:
__tools\gm__, __tools\perl__, __tools\webmerge__. Then you
can use the run script __tools\webmerge\webmerge.bat__

Demo Examples
=============
- http://webmerge.ocbnet.ch/webmerge/example/sprites/fam/
- http://webmerge.ocbnet.ch/webmerge/example/sprites/hires/
- http://webmerge.ocbnet.ch/webmerge/example/embedder/index.php
- http://webmerge.ocbnet.ch/webmerge/example/embedder/index.html

Performance
===========
The performance should be quite decent but is definitely not 100%
optimal. Altough I tried to use the best methods wherever possible.
From code profiling the sprites examples, one of the most promising
optimizations would be to implement OCBNET::Packer::2D in XS code (C).
You can view a NYTPROF Performance Profile of the sprite example here:
- http://webmerge.ocbnet.ch/webmerge/nytprof/

Command Line Options
====================
    -f, --configfile       main xml configuration
    -d, --doctype          how to render includes [html|xhtml|html5]
    -j, --jobs             number of jobs (commands) to run simultaneously

    -w, --watchdog         start the watchdog process (quit with ctrl+c)
    --webserver            start the webserver process (quit with ctrl+c)
    --webport              port number for the webserver (default 8000)

    --webroot              webroot directory to render absolute urls
    --absoluteurls         export urls as absolute urls (from webroot)

    --import-css           inline imported css files into stylesheet
    --import-scss          inline imported scss files into stylesheet
    --rebase-urls-in-css   adjust urls in css files to parent stylesheet
    --rebase-urls-in-scss  adjust urls to scss files to parent stylesheet
    --rebase-imports-css   adjust import urls for css files (only if not inlined)
    --rebase-imports-scss  adjust import urls for scss files (only if not inlined)

    --referer              optional referer url for external downloads
    --inlinedataexts       file extensions to inline (comma separated)
    --inlinedatamax        maximum file sizes to inline into stylesheets

    --crc-check            run crc check before exiting
    --crc-file             write crc file beside generated files
    --crc-comment          append crc comment into generated files

    --fingerprint          add fingerprints to includes (--fp)
    --fingerprint-dev      for dev context [query|directory|file] (--fp-dev)
    --fingerprint-live     for live context [query|directory|file] (--fp-live)

    --txt-type             text type [nix|mac|win]
    --txt-remove-bom       remove superfluous utf boms
    --txt-normalize-eol    normalize line endings to given type
    --txt-trim-trailing    trim trailing whitespace in text files

    --headtmpl             text to prepend to generated files
    --jsdeferer            javascript loader for defered loading
    --tmpl-embed-js        template for js embedder generator
    --tmpl-embed-php       template for php embedder generator

        --action           use to disable all actions
    -p, --prepare          enable/disable prepare blocks
    -o, --optimize         enable/disable optimizer blocks
    -m, --merge            use to disable all merge blocks
        --css              enable/disable css merge blocks
        --js               enable/disable js merge blocks
    -i, --headinc          enable/disable headinc blocks
    -e, --embedder         enable/disable embedder blocks

    -l, --level            set optimization level (0-9)

    --dev                  enable/disable dev targets
    --join                 enable/disable join targets
    --minify               enable/disable minify targets
    --compile              enable/disable compile targets
    --license              enable/disable license targets

    --optimize-txt         enable/disable optimizer for text files (--txt)
    --optimize-jpg         enable/disable optimizer for jpg images (--jpg)
    --optimize-gif         enable/disable optimizer for gif images (--gif)
    --optimize-png         enable/disable optimizer for png images (--png)
    --optimize-mng         enable/disable optimizer for mng images (--mng)
    --optimize-zip         enable/disable optimizer for zip archives (--zip)
    --optimize-gz          enable/disable optimizer for gz archive files (--gz)

    -dbg, --debug          enable/disable debug mode

    --man                  full documentation
    --opts                 list command line options
    -?, --help             brief help message with options


Credits
=======
Initial developement was done while working at http://www.rtp.ch.
Thanks a lot to them for allowing me to publish this utility!
