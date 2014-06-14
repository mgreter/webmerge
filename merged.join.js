// Code to bootstrap the page

(function(jQuery)
{

	jQuery(function()
	{

		// ####################################################################################

		// mark body tag for selectors if javascript is enabled
		jQuery('body').addClass('js').removeClass('no-js');

		function columnize ()
		{

			// get item from previous run or
			var columnized = jQuery(this).next();

			// ... create new to put columnized content
			if ( ! columnized.hasClass('columnized') )
			{ columnized = jQuery('<div class="columnized">') }

			// add target to page
			jQuery(this).after(columnized);

			// show for correct measuring
			jQuery(columnized).css({
				'display' : 'block'
			});

			// columnize every elements
			jQuery(this).css({
				'display' : 'block'
			}).columnize({
				columns: 2,
				buildOnce: true,
				target: columnized,
				lastNeverTallest : true
			}).css({
				'display' : ''
			});

			// remove explicit show
			jQuery(columnized).css({
				'display' : ''
			});

		}

		// ####################################################################################

		// create query levels object with all responsive breakpoints
		var querylevels = { XXS: 10, XS: 20, S: 30, M: 50, L: 70, XL: 80, XXL : 90 };

		// init mediaquery object to attach event handlers and query current status
		window.mediaquery = new ocbnet.mediaquery (70, querylevels);

		// ####################################################################################

		// register deferred layout manager call (run after anythin else)
		window.setTimeout(function () { OCBNET.Layout(true); }, 0);

		// ####################################################################################

		// process all elements to be columnized
		jQuery('.columnize').each(function ()
		{

			mediaquery.onChangeAndInit(jQuery.proxy(columnize, this));

		});
		// EO each .columnize

		// ####################################################################################

		// sets focus class on parent node
		ocbnet.legacy.focus('#nav-top A',
			function() { return this.parents('LI') }
		);

		// ####################################################################################

		// browser detection - feature detection
		// did not to work for 'content' or ':after'
		var agent = navigator.appName.toLowerCase();
		var version = parseInt(navigator.appVersion, 10);

		// minor and easy fix for ie7 and below for fontawesome
		if ((agent == "microsoft internet explorer" || agent == "ie") && version <= 7)
		{
			// add the char directly into the html
			jQuery('#footer .social .twitter A').html("");
			jQuery('#footer .social .youtube A').html("");
			jQuery('#footer .social .facebook A').html("");
		}

		// ####################################################################################

	})
})
(jQuery);

// Code to bootstrap the menu

(function(jQuery)
{
	jQuery(function()
	{

		// ####################################################################################
		var menu = jQuery.jPanelMenu({

			duration: 300,
			menu: '#nav-top',
			direction: 'right',
			openPosition: '300px',
			shiftFixedChildren: true,
			trigger: '.menu-toggle A',

			before: function()
			{
				// use as much space as available, but not more than 300 pixels
				this.openPosition = Math.min(300, jQuery(document).width() - 55)
				// update some internal jPanelMenu styles
				jQuery(menu.menu).width(this.openPosition);
			}

		});

		jQuery(window).on('resize', jQuery.proxy(menu.close, menu));

		// start
		menu.on();

		mediaquery.onChange(function (cur, prv)
		{

			// if (prv > 20 && cur <= 20) menu.on()
			// if (prv <= 20 && cur > 20) menu.off()

		});
/*


		jQuery('#nav-top').wrapInner('<DIV>');

		jQuery('.menu-toggle').sidr({
			side: 'right',
			name: 'top-menu',
			source: '#nav-top>DIV'
		});

*/
		// jQuery('.sidr.right').addClass('jPanelMenu');

		// jQuery.sidr('toggle', 'top-menu');

		// ####################################################################################

	})
})
(jQuery);

// Code to bootstrap the page

(function(jQuery)
{
	jQuery(function()
	{

		// ####################################################################################

		// mark body tag for selectors if javascript is enabled
		jQuery('.tiles').each(function (i, root)
		{

			// get array with all tiles
			var tiles = jQuery('.tile', root).toArray();

			// get layout position/priority array
			var prios = jQuery.map(tiles, function (tile)
			{
				return [ jQuery.map(
					jQuery(tile).data('pos').split(/\s*,\s*/),
					function (prio) { return [ prio.split(/\s*:\s*/) ] })
				];
			});

			// create overlay for tiles
			jQuery.each(tiles, function (t, tile)
			{
				jQuery(tile).filter('.overlay')
				.find('A').each(function (a, lnk)
				{
					jQuery(lnk).append(
						jQuery('<span class="overlay">').append(
							jQuery('<span class="inner">').text(
								jQuery(lnk).find('IMG').prop('alt')
							)
						)
					)
				});
			});

			var cache = [];

			// layout function
			function layout (mode, width)
			{

				// fluid mode
				if (mode == 4)
				{
					// reset tiles
					jQuery(tiles).css({
						'top': '',
						'left': '',
						'width': '',
						'height': '',
						'position': ''
					})
					// reset root
					jQuery(root).css({
						'height': ''
					});
				}
				// layout myself
				else
				{

					// use cache
					if (!cache[mode])
					{

						// create defaults for all tiles
						var i = prios.length; while (i--)
						{
							// create array for tile
							// stores different modes
							if (!prios[i]) prios[i] = [];
							// stores col and prio by mode
							if (!prios[i][mode]) prios[i][mode] = [];
							// check if tile has column set
							if (typeof prios[i][mode][0] == 'undefined')
							{
								var min = 1; var max = mode == 2 ? 3 : 2;
								if (mode >= 2 && jQuery(tiles[i]).is('.tile-wide,.tile-big')) max --;
								prios[i][mode][0] = Math.floor(Math.random() * (max - min + 1)) + min;
							}
							// check if tile has priority set
							if (typeof prios[i][mode][1] == 'undefined')
							{
								prios[i][mode][1] = Math.floor(Math.random() * (20));
							}
						}

						// create empty distribution
						var cols = [[],[],[],[],[],[]];

						// distribute tiles to cols
						for (var col = 0; col < 6; col++)
						{
							var i = prios.length; while (i--)
							{
								if (prios[i][mode][0] == col)
								{ cols[col].push(i); }
							}
						}

						// sort cols by priorities
						for (var col = 0; col < 6; col++)
						{
							cols[col].sort(function (a, b)
							{
								return prios[a][mode][1] - prios[b][mode][1];
							})
						}

						// store to cache
						cache[mode] = cols;

					}

					// assign from cache
					var cols = cache[mode];

					// left position
					var left = - width;

					// maximum height
					var maxheight = 0;

					// store layout gaps
					var gaps_cur = [];

					// layout tiles in cols
					for (var col = 0; col < 6; col++)
					{

						// store next gaps
						var gaps_right = [];

						// top position
						var top = 0;

						// layout tiles in cols
						for (var row = 0; row < cols[col].length; row++)
						{

							// get the tile index
							var i = cols[col][row]
							// get the tile node
							var tile = tiles[i];
							// and the prio object
							var prio = prios[i];

							// calc z-index
							var zindex = 100;

							// put into foreground if the tile will move
							if (parseInt(jQuery(tile).css('top')) != top) zindex = 98000;
							if (parseInt(jQuery(tile).css('left')) != left) zindex = 99000;

							zindex += row;

							// position tile
							jQuery(tile).css({
								'top' : top + 'px',
								'left' : left + 'px',
								'z-index' : zindex,
								'position' : 'absolute'
							});

							// get the height of the tile
							var height = jQuery(tile).height();

							// check if we are in a gap
							while (gaps_cur.length > 0)
							{
								// avoid gaps
								if (
									// start is in gap
									top > gaps_cur[0][0] ||
									// or end will be in gap
									top + height > gaps_cur[0][0]
								)
								{
									var gap = gaps_cur.shift();
									top = gap[0] + gap[1];
								}
								// abort while
								else break;
							}


							// position tile
							jQuery(tile).css({
								'top' : top + 'px'
							});

							// store gaps for next col
							if (
								jQuery(tile).hasClass('tile-big') ||
								jQuery(tile).hasClass('tile-wide')
							)
							{
								gaps_right.push([top, height]);
							}

							// increase offset
							top += height;

						}

						maxheight = Math.max(maxheight, top);

						// shift gaps array
						gaps_cur = gaps_right;

						// increase offset
						left += width;

					}

					jQuery(root).css('height', maxheight);

				}

				// create defaults for all tiles
				var n = prios.length; while (n--)
				{
					jQuery('.toolbar .status', tiles[n]).text((prios[n][mode] || []).join(':'));
				}

			}
			// EO Layout

			// call initial layout only if mediaquery
			// will not dispatch a change event itself
			if (mediaquery.getLevel() == 70) layout(1, 245);

			// called when mediaquery changes
			mediaquery.onChange(function ()
			{

				// layout mode
				var mode = 4;
				// tiles width
				var width = 295;

				// change according to mediaquery
				if      (mediaquery.ge(90)) { mode = 0; width = 295; } // XXL
				else if (mediaquery.ge(80)) { mode = 1; width = 295; } // XL
				else if (mediaquery.ge(70)) { mode = 1; width = 245; } // L
				else if (mediaquery.ge(50)) { mode = 1; width = 235; } // M
				else if (mediaquery.ge(30)) { mode = 2; width = 235; } // S
				else if (mediaquery.ge(20)) { mode = 3; width = 270; } // XS
				else if (mediaquery.ge(10)) { mode = 4; width = 'auto'; } // XXS

				// execute layout
				layout(mode, width)

			});
			// EO onChange

			function move (i, action)
			{

				// layout mode
				var mode = 4;
				// tiles width
				var width = 295;

				// change according to mediaquery
				if      (mediaquery.ge(90)) { mode = 0; width = 295; } // XXL
				else if (mediaquery.ge(80)) { mode = 1; width = 295; } // XL
				else if (mediaquery.ge(70)) { mode = 1; width = 245; } // L
				else if (mediaquery.ge(50)) { mode = 1; width = 235; } // M
				else if (mediaquery.ge(30)) { mode = 2; width = 235; } // S
				else if (mediaquery.ge(20)) { mode = 3; width = 270; } // XS
				else if (mediaquery.ge(10)) { mode = 4; width = 'auto'; } // XXS

			// get layout position/priority array
				var pos = jQuery.map(
					jQuery(this).data('pos').split(/\s*,\s*/),
					function (prio) { return [ prio.split(/\s*:\s*/) ] }
				);

				delete cache[mode];

				if (action == "up") prios[i][mode][1] --;
				if (action == "down") prios[i][mode][1] ++;
				if (action == "left") prios[i][mode][0] --;
				if (action == "right") prios[i][mode][0] ++;

				if (prios[i][mode][0] < 0) prios[i][mode][0] = 0;
				if (prios[i][mode][0] > 5) prios[i][mode][0] = 5;

				// execute layout
				layout(mode, width)

				return false;

			}

			var mode = 0; var width = 295;

			// change according to mediaquery
			if      (mediaquery.ge(90)) { mode = 0; width = 295; } // XXL
			else if (mediaquery.ge(80)) { mode = 1; width = 295; } // XL
			else if (mediaquery.ge(70)) { mode = 1; width = 245; } // L
			else if (mediaquery.ge(50)) { mode = 1; width = 235; } // M
			else if (mediaquery.ge(30)) { mode = 2; width = 235; } // S
			else if (mediaquery.ge(20)) { mode = 3; width = 270; } // XS
			else if (mediaquery.ge(10)) { mode = 4; width = 'auto'; } // XXS

			/*
			jQuery(tiles).each(function (i, tile)
			{
				var toolbar = jQuery('<div class="toolbar">');
				toolbar.append(jQuery('<a href="#" class="up">Up</a>').on('click', jQuery.proxy(move, tile, i, 'up')));
				toolbar.append(jQuery('<a href="#" class="down">Down</a>').on('click', jQuery.proxy(move, tile, i, 'down')));
				toolbar.append(jQuery('<a href="#" class="left">Left</a>').on('click', jQuery.proxy(move, tile, i, 'left')));
				toolbar.append(jQuery('<a href="#" class="right">Right</a>').on('click', jQuery.proxy(move, tile, i, 'right')));
				toolbar.append(jQuery('<span class="status">' + (prios[i][mode] || []).join(':') + '</span>'));
				jQuery(tile).append(toolbar)
			});
			*/

		});

		// ####################################################################################

	})
})
(jQuery);

// Code to bootstrap the page

(function(jQuery)
{
	jQuery(function(jQuery)
	{

		var infobox = jQuery('<DIV>').css({
			'top' : '0px',
			'left' : '0px',
			'z-index' : '999999',
			'padding' : '4px 8px',
			'position' : 'fixed',
			'border' : '3px solid red',
			'background-color' : 'white'
		});

		function updateInfobox ()
		{
			infobox.text(
				mediaquery.getCurrentIdent()
			);
		}

		jQuery('BODY').append(infobox);

		// demo for media query scope
		// output message for developers
		mediaquery.onChange(function (to, from)
		{

			// resolve numbers to ids
			to = mediaquery.getIdent(to);
			from = mediaquery.getIdent(from);

			// print out a message about the scope change
			console.log('changed media query scope from ', from, ' to ', to, ' at ', $('body').innerWidth());

			// update infobox
			updateInfobox();

		}, -9999);
		// EO mediaquery.onChange

		// update infobox on resize
		jQuery(window).on('resize', updateInfobox);

		// enable some specific dev hotkeys
		jQuery(document).on('keypress', function (evt)
		{

			if (evt.charCode == 103) jQuery('BODY').toggleClass('grid');

		});

		// call on load
		updateInfobox();

	})
})
(jQuery);

/* crc: 93641C5CDE7E3B75CC3D2CE32409D1A1 */
