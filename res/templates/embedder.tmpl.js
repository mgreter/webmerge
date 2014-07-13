(function()
{

	//#########################################################################

	// declare namespace for webmerge
	if (typeof window.webmerge == 'undefined') window.webmerge = {};

	//#########################################################################

	// http://stackoverflow.com/questions/4003823/javascript-getcookie-functions/4004010#4004010
	if (typeof String.prototype.trimLeft !== "function")
	{
		String.prototype.trimLeft = function()
		{ return this.replace(/^\s+/, ""); };
	}
	if (typeof String.prototype.trimRight !== "function")
	{
		String.prototype.trimRight = function()
		{ return this.replace(/\s+$/, ""); };
	}
	if (typeof Array.prototype.map !== "function")
	{
		Array.prototype.map = function(callback, thisArg)
		{
			for (var i=0, n=this.length, a=[]; i<n; i++)
			{ if (i in this) a[i] = callback.call(thisArg, this[i]); }
			return a;
		};
	}

	var c = document.cookie, v = 0;

	webmerge.COOKIE = {};

	if (document.cookie.match(/^\s*\$Version=(?:"1"|1);\s*(.*)/)) { c = RegExp.$1; v = 1; }

	if (v === 0)
	{
		c.split(/[,;]/).map(function(cookie)
			{
				var parts = cookie.split(/=/, 2),
				            name = decodeURIComponent(parts[0].trimLeft()),
				            value = parts.length > 1 ? decodeURIComponent(parts[1].trimRight()) : null;
				webmerge.COOKIE[name] = value;
			}
		);
	}
	else
	{
		c.match(/(?:^|\s+)([!#$%&'*+\-.0-9A-Z^`a-z|~]+)=([!#$%&'*+\-.0-9A-Z^`a-z|~]*|"(?:[\x20-\x7E\x80\xFF]|\\[\x00-\x7F])*")(?=\s*[,;]|$)/g)
		 .map(function($0, $1)
		      {
		      	var name = $0, value = $1.charAt(0) !== '"' ? $1 :
		      	           $1.substr(1, -1).replace(/\\(.)/g, "$1");
		      	webmerge.COOKIE[name] = value;
		      }
		 );
	}

	//#########################################################################

	webmerge.SERVER = { 'HTTP_USER_AGENT': navigator.userAgent };

	//#########################################################################

	// precreated include file by webmerge
	var includes = %%includes%%;

	//#########################################################################

	webmerge.embed = function (context, did, klass, debug)
	{

		//#########################################################################

		if (typeof did == 'undefined' || did === null) did = '';
		if (typeof debug == 'undefined' || debug === null) debug = 1;

		//#########################################################################

		// this is a bug hotfix, should not be preset
		if (context == 'dev') { context = 'live'; }

		//#########################################################################

%%switcher%%

		//#########################################################################

		// assert that variables are set up
		if (!klass) { klass = 'default'; }
		if (!context) { context = 'live'; }

		//#########################################################################

		// no debug message by default
		var debugmsg = '';

		// create a debug message to be printed out
		if (debug) { debugmsg = 'webmerge: ' + [context, did, klass].join(':'); }

		// wrap debug message within a html comment if debug equals one
		if (debug == 1) { debugmsg = '<!-- ' + debugmsg + ' -->'; }

		// add a newline to the debug message
		if (debug) { debugmsg += "\n"; }

		// test if include for favored class exists
		if (includes[did][context][klass])
		{
			// write the includes for domain and context
			return(debugmsg + includes[did][context][klass]);
		}
		else if (includes[did][context]['default'])
		{
			// write the includes for domain and context
			return(debugmsg + includes[did][context]['default']);
		}
		else
		{
			// give an error message as html comment
			return '<!-- webmerge found no include: ' + [context, did, klass].join(':') + ' -->';
		}

		//#########################################################################

	}

	//#########################################################################

	webmerge.embed.select = function (rootline)
	{

		//#########################################################################

		for (var i = 0, li = rootline.length; i < li; i++)
		{ for (var did in includes) if (rootline[i] == did) return did; }

		//#########################################################################

		return rootline[-1];

		//#########################################################################

	}

	//#########################################################################

})();

