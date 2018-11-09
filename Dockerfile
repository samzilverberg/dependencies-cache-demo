#
# this dockerfile builds an image with sbt cached deps
#

##############
# base docker image
#   alpine image with sbt
FROM openjdk:8-alpine as base

ENV SBT_VERSION 0.13.11
ENV SBT_HOME /usr/local/sbt
ENV PATH ${PATH}:${SBT_HOME}/bin
# Install sbt
RUN apk add --update curl ca-certificates bash && \
	curl -sL "http://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz" | gunzip | tar -x -C /usr/local && \
    echo -ne "- with sbt $SBT_VERSION\n" >> /root/.built &&\
    apk del curl


##############
# docker image with project code to d/l deps
FROM base as deps

# add project dir with build.sbt and other project definitions
ADD . /project
WORKDIR /project

# Download all the project dependencies into
# /deps-cache/.ivy2 and /deps-cache/.sbt by running `sbt update` command
RUN sbt -Dsbt.ivy.home=/deps-cache/.ivy2/ \
        -Dsbt.boot.directory=/deps-cache/.sbt/boot \
        -Dsbt.global.base=/deps-cache/.sbt \
        update compile < /dev/null


##############
# final docker image without project src (only sbt deps)
FROM base

COPY --from=deps /deps-cache/.ivy2 /deps-cache/.ivy2
COPY --from=deps /deps-cache/.sbt /deps-cache/.sbt