Pack Webmerge into standalone executable
========================================

This is done by using [PAR::Packer](http://search.cpan.org/~rschupp/PAR-Packer/). The scripts use a local perl
version which can be installed from the webmerge-perl portables. The additional package can be installed by
calling the prepare scripts (may take a long time). I also added an icon from the free [crystal
clear](http://commons.wikimedia.org/wiki/Crystal_Clear) Iconset.

This is so far just a proof of concept. It will just pack the perl part of webmerge, all other externals still
have to be installed inside the global path.
