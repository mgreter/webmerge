###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# OCBNET Spriteset generator from annotated css
# Inspired by http:://www.csssprites.org
####################################################################################################
# more ideas:
# ------------------------------------------------
# move all selectors for sprite images to
# one place to reference image only once
# this may work well with inline data urls?
# where to place it to not break inheritance?
# -> use css inheritance to place it into a
# -> common selector, so define the spriteset
# -> in a common block to know where to place it
# ------------------------------------------------
# support for multiple background images (css3)
# ------------------------------------------------
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
