#!/bin/sh

pushd `dirname $0` > /dev/null

wget "http://dl.google.com/closure-compiler/compiler-latest.zip"
unzip -o "compiler-latest.zip" && rm "compiler-latest.zip"

popd > /dev/null