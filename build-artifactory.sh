#!/bin/bash

# fail on any error
set -e

readonly CACHE_DIR=/halfpipe-cache
readonly REPOS_FILE=$CACHE_DIR/.natcar-repos
export CREDS_FILE=$CACHE_DIR/.natcar-creds


#######################################
### create credentials file for sbt ###
#######################################

if [[ -z "$ARTIFACTORY_USERNAME" ]]; then
    echo "env var ARTIFACTORY_USERNAME not set. will try to read it from vault"
    ARTIFACTORY_USERNAME=$(vault read -field=username springernature/nature-careers/artifactory)
fi

if [[ -z "$ARTIFACTORY_PASSWORD" ]]; then
    echo "env var ARTIFACTORY_PASSWORD not set. will try to read it from vault"
    ARTIFACTORY_PASSWORD=$(vault read -field=password springernature/nature-careers/artifactory)
fi

echo "realm=Artifactory Realm
host=springernature.jfrog.io
user=$ARTIFACTORY_USERNAME
password=$ARTIFACTORY_PASSWORD
" > $CREDS_FILE


#########################################
### create repositories file for sbt ###
#########################################

# https://www.scala-sbt.org/1.0/docs/Resolvers.html

# repo locations for reference
#maven-central https://repo1.maven.org/maven2/
#sonatype-oss-releases https://oss.sonatype.org/content/repositories
#sonatype-public https://oss.sonatype.org/content/repositories/public
#sonatype-releases https://oss.sonatype.org/content/repositories/releases
#sonatype-snapshots https://oss.sonatype.org/content/repositories/snapshots
#typsafe root http://repo.typesafe.com/typesafe
#typesafe-ivy-releases: https://repo.typesafe.com/typesafe/ivy-releases/, [organization]/[module]/[revision]/[type]s/[artifact](-[classifier]).[ext], bootOnly
#typesafe-maven-releases: https://dl.bintray.com/typesafe/maven-releases/
#sbt root http//repo.scala-sbt.org/scalasbt
#jcenter https://jcenter.bintray.com/
#sbt-ivy-snapshots: https://repo.scala-sbt.org/scalasbt/ivy-snapshots/, [organization]/[module]/[revision]/[type]s/[artifact](-[classifier]).[ext], bootOnly
#sbt-plugins-community https://repo.scala-sbt.org/scalasbt/sbt-plugin-releases

echo "[repositories]
local
artifactory-releases-maven: https://springernature.jfrog.io/springernature/libs-release/
artifactory-releases-ivy: https://springernature.jfrog.io/springernature/libs-release/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]
artifactory-snapshots-maven: https://springernature.jfrog.io/springernature/libs-snapshot/
artifactory-snapshots-ivy: https://springernature.jfrog.io/springernature/libs-snapshot/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]
" > $REPOS_FILE

# halfpipe worker+task cache
if [ -d $CACHE_DIR ]; then
  echo "local halfpipe worker cache at: $CACHE_DIR"
  ls -lah $CACHE_DIR/
  du -sh $CACHE_DIR/
  mkdir -p $CACHE_DIR/.sbt
  mkdir -p $CACHE_DIR/.sbt/boot
  mkdir -p $CACHE_DIR/.sbt/1.0/plugins
  mkdir -p $CACHE_DIR/.ivy2
   # point ivy (deps) and sbt related caches to the worker cache folder
  SBT_OPTIONS="-Dsbt.repository.config=$REPOS_FILE
    -Dsbt.boot.credentials=$CREDS_FILE
    -Dsbt.override.build.repos=true
    -Dsbt.ivy.home=$CACHE_DIR/.ivy2/
    -Dsbt.boot.directory=$CACHE_DIR/.sbt/boot
    -Dsbt.global.base=$CACHE_DIR/.sbt"
fi

sbt ${SBT_OPTIONS} ";project api-gateway ;clean ;cleanFiles ;test ;dist" < /dev/null
