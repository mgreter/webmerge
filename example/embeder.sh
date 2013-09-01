#!/bin/sh

pushd `dirname $0` > /dev/null

../webmerge.sh -f conf/embeder.conf.xml "$@"

popd > /dev/null