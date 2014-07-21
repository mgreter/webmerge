#!/bin/sh

pushd `dirname $0` > /dev/null

wget "https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.zip" -o yuicompressor.jar

popd > /dev/null