#!/bin/sh

pushd `dirname $0`

../webmerge.sh -f conf/optimize.conf.xml -o -jpg -png "$@"

popd