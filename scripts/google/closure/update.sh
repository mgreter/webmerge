#!/bin/sh

pushd `dirname $0` > /dev/null

if type "wget" > /dev/null; then
	wget "http://dl.google.com/closure-compiler/compiler-latest.zip"
elif type "curl" > /dev/null; then
	curl "http://dl.google.com/closure-compiler/compiler-latest.zip" -o compiler-latest.zip
else
	echo "we either need curl or wget to download closure compiler"
	exit 1 # exit with error status
fi

unzip -o "compiler-latest.zip" && rm "compiler-latest.zip"

if [ -f closure-compiler-*.jar ]; then
	if [ -f compiler.jar ]; then
		echo "remove old compiler"
		rm compiler.jar
	fi
	echo "rename unpacked compiler"
	mv closure-compiler-*.jar compiler.jar
fi

popd > /dev/null