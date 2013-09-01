#!/bin/sh

pushd `dirname $0` > /dev/null

perl scripts/webmerge.pl "$@"

popd > /dev/null