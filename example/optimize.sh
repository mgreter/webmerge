#!/bin/sh

pushd `dirname $0` > /dev/null

../webmerge.sh -f conf/optimize.conf.xml -o -jpg -png "$@"

popd > /dev/null