#!/bin/sh

pushd `dirname $0`

perl scripts/webmerge.pl "$@"

popd