#!/bin/sh

pushd `dirname $0` > /dev/null

../../webmerge.sh -f ../conf/sprites.conf.xml -o -png hires "$@"

popd > /dev/null