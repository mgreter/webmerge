/*

  So far we only support head.js and jQuery out of the box (add require.js etc)
  To add more prerequisites for rtp.ready you can use rtp.ready.prerequisite(id)

*/

if (!window.rtp) window.rtp = {}; // ns

/* @@@@@@@@@@ CONSTRUCTOR @@@@@@@@@@ */

(function()
{

	// local static variables
	var callbacks = [];
	var prerequisite = {};

	// static closure function
	var check = function()
	{

		// wait for jquery if found
		if (
			typeof jQuery !== 'undefined' &&
			typeof prerequisite.jquery === 'undefined'
		) {
			prerequisite.jquery = false;
			jQuery(function() { prerequisite.jquery = true; check(); });
		}

		// wait for headjs if found
		if (
			typeof head !== 'undefined' &&
			typeof prerequisite.headjs === 'undefined'
		) {
			prerequisite.headjs = false;
			head.ready(function() { prerequisite.headjs = true; check(); });
		}

		// is everything loaded?
		var loaded_all = true;
		// check each prerequisite
		for(var key in prerequisite)
		{
			// all must be true to continue
			if (prerequisite[key] === false)
			{ loaded_all = false; break; }
		}
		// was everything loaded?
		if (loaded_all)
		{
			// execute all callbacks
			while(callbacks.length)
			{ (callbacks.shift())(); }
		}

	};
	// EO check

	// static global function
	// register callback functions
	rtp.ready = function ()
	{

		// register the callbacks for the final load event
		callbacks = callbacks.concat(Array.prototype.slice.call(arguments));

		// check if we can execute right away
		check();

	};
	// EO rtp.ready

	// static global function
	// return a function which needs to be called,
	// afterwards we may execute registered callbacks
	rtp.ready.prerequisite = function(id)
	{

		// register prerequisite
		prerequisite[id] = false;

		// return function to satisfy and finish the prerequisite
		return function () { prerequisite[id] = true; check(); }

	};
	// EO rtp.ready.prerequisite

	// @@@ rtp.isFn @@@
	// check if input is a function
	rtp.isFn = function(fn)
	{
		return Object.prototype.toString.call(fn)
			== '[object Function]';
	}
	// EO rtp.isFn

	// @@@ rtp.log @@@
	// log something somewhere
	rtp.log = function(msg)
	{

		// map to console log function if possible
		if (typeof console !== 'undefined' && rtp.isFn(console.log)) console.log(msg)

	};
	// EO rtp.log

})();