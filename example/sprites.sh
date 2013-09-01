#!/bin/sh

pushd `dirname $0` > /dev/null

../webmerge.sh -f conf/sprites.conf.xml -o -png fam hires "$@"

popd > /dev/null