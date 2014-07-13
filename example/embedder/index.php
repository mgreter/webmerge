<html>
	<head>

		<title>Webmerge example</title>

		<?php

			// declare path and rootline array
			$path = ''; $rootline =  array();

			// get the path info without issuing a warning and sensible default
			$pathinfo = isset ($_SERVER['PATH_INFO']) ? $_SERVER['PATH_INFO'] : '';

			// process each directory in full path
			foreach (explode('/', $pathinfo) as $pid) {

				// prepend full path into our rootline
				array_unshift($rootline, $path .= $pid . '/');

			}

			// load the embedder to select and embed includes
			include('admin/webmerge/generated/embedder.php');
			$domain = tx_rtpwebmerge_embed_data::select($rootline);
			$include = tx_rtpwebmerge_embed_data::embed('live', $domain);

			// print into header
			print $include;

		?>

	</head>
	<body>

		<h1>Webmerge example</h1>

		<p>
			Switch cookie context:
			<a href="javascript:void((function(){document.cookie='WEBMERGE_CONTEXT=dev; Expires=Tue, 1 Jan 2050 12:00:00 GMT; Path=/;'; location.reload(true)})())">DEV</a>
			<a href="javascript:void((function(){document.cookie='WEBMERGE_CONTEXT=live; Expires=Tue, 1 Jan 2050 12:00:00 GMT; Path=/;'; location.reload(true)})())">LIVE</a>
			<a href="javascript:void((function(){document.cookie='WEBMERGE_CONTEXT=clear; Expires=Tue, 1 Jan 1950 12:00:00 GMT; Path=/;'; location.reload(true)})())">CLEAR</a>
		</p>

		<p>
			Go to page:
			<a href="<?php print($_SERVER['SCRIPT_NAME']); ?>/sub/page">sub page</a>
			<a href="<?php print($_SERVER['SCRIPT_NAME']); ?>/home/page">home page</a>
			<a href="<?php print($_SERVER['SCRIPT_NAME']); ?>/other/page">other page</a>
		</p>

		CSS: <ul>
			<li style="display:none;" class="all">all.css is loaded</li>
			<li style="display:none;" class="dev">dev.css is loaded</li>
			<li style="display:none;" class="live">live.css is loaded</li>
			<li style="display:none;" class="inc">inc.css is loaded</li>
			<li style="display:none;" class="sub">sub.css is loaded</li>
		</ul>

		<hr>

		<pre><?php print htmlspecialchars($include) ?></pre>

	</body>
</html>