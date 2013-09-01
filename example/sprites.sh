#!/bin/sh

pushd `dirname $0`

../webmerge.sh -f conf/sprites.conf.xml -o -png fam hires "$@"

popd