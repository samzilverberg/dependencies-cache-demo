#!/bin/bash

# fail on any error
set -e

# cache usage:
# use SBT_OPTIONS to point ivy (deps) and sbt related caches to the a cache folder
# - prefer deps-cache from docker image if available
# - fallback to some other cache if available
if [ -d /deps-cache ]; then
    CACHE=/deps-cache
elif [ -d /some-other-cache ]; then
    CACHE=/some-other-cache
    mkdir -p $CACHE/.sbt
fi
if [ -n "$CACHE" ]; then
  SBT_OPTIONS="-Dsbt.ivy.home=$CACHE/.ivy2/ \
  -Dsbt.boot.directory=$CACHE/.sbt/boot \
  -Dsbt.global.base=$CACHE/.sbt"
fi

sbt ${SBT_OPTIONS} ";project api-gateway ;clean ;cleanFiles ;test ;dist"
