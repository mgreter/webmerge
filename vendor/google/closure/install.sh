#!/bin/sh

if [ ! -e "`dirname $0`/compiler.jar" ]; then `dirname $0`/update.sh; fi

sleep 3