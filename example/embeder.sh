#!/bin/sh

pushd `dirname $0`

../webmerge.sh -f conf/embeder.conf.xml "$@"

popd