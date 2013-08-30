####################################################################################################
# this block stacks the sprites vertically
# or horizontally together (and aligned)
####################################################################################################
# more ideas:
# ------------------------------------------------
# move all selectors for sprite images to
# one place to reference image only once
# this may work well with data data urls?
# where to place it to not break inheritance?
# ------------------------------------------------
# support for multiple background images (css3)
# ------------------------------------------------
####################################################################################################
# buggy: media-gfx/graphicsmagick-1.3.16-r1
# fixed: media-gfx/graphicsmagick-1.3.18
####################################################################################################
package OCBNET::Spritesets;
####################################################################################################

# just load all other modules
use OCBNET::Spritesets::CSS;
use OCBNET::Spritesets::Packing;
use OCBNET::Spritesets::Block;
use OCBNET::Spritesets::Canvas;
use OCBNET::Spritesets::Container;
use OCBNET::Spritesets::Corner;
use OCBNET::Spritesets::Edge;
use OCBNET::Spritesets::Fit;
use OCBNET::Spritesets::Sprite;
use OCBNET::Spritesets::Stack;

####################################################################################################
# how to use it
####################################################################################################

####################################################################################################
####################################################################################################
1;
