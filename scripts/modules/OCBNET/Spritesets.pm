###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# OCBNET Spriteset generator from annotated css
# Inspired by http:://www.csssprites.org
####################################################################################################
# more ideas:
# ------------------------------------------------
# support for multiple background images (css3)
# ------------------------------------------------
# the padding is (mainly?) needed for the repeater,
# as it has to know where to put the sprite. It will
# always only will make sense (css wise) to treat it
# as a left/top value -> so rename if to offset-[xy].
# A padding-bottom/right will only increase the box
# size, so handle that before and pass only dimensions.
# ------------------------------------------------
# A sprite has a img-size, box-size and a offset!
# Some sprites are able to remove some paddings ...
####################################################################################################
# buggy: media-gfx/graphicsmagick-1.3.16-r1
# fixed: media-gfx/graphicsmagick-1.3.18
####################################################################################################
package OCBNET::Spritesets;
####################################################################################################

# default fitter algorithm
use OCBNET::Packer::2D;

# load main spriteset modules
use OCBNET::Spritesets::Block;
use OCBNET::Spritesets::Sprite;
use OCBNET::Spritesets::Canvas;
use OCBNET::Spritesets::Container;
use OCBNET::Spritesets::Corner;
use OCBNET::Spritesets::Stack;
use OCBNET::Spritesets::Edge;
use OCBNET::Spritesets::Fit;

# load the parser for stylesheets
use OCBNET::Spritesets::CSS::Parser;

####################################################################################################
####################################################################################################
1;
