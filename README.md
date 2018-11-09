purpose of repo
###############

showing 2 ways to cache deps for build

1) with artifactory
2) by building a docker image that contains deps

i will also explain a little about the sbt build phases, to get a better understanding of what needs to be cached.

### whats all these files in the project?
i used sbt build tool in this example and a seed play framework project via:  
```bash
sbt new playframework/play-scala-seed.g8
```
play framework version is 2.18
I removed the gradle and g8 template related files from the seed project.


SBT BUILD STAGES
################

its important to understand that SBT has different stages when loading your sbt project configuration and building it.

1. global/boot stage: sbt version specificed in `project/build.properties` will be fetched, along with scala version needed.
2. plugins stage: plugins from the `project/` dir will be fetched. if you have any global plugins specified (if you have them you know what i'm talking about) they will be fetched first.
3. project stage: project dependencies from build.sbt will be fetched

each stage has its own repositories. and if credentials are needed then they need to be defined for each stage in a different location.

- global credentails: can be passed via `-Dsbt.boot.credentials=file-path-here`
- plugin credentials: need to be defined in whatever plugins.sbt your using
- project credentials: need to be defined for the build.sbt of your project




DOCKER IMAGE
############

you can just "bundle" all your deps into a docker image, and when building in a CI env make sure that you build within that image and point any cache related dirs to the cache dirs in the docker image.

###main advantages: simplicity & speed.
simple: building the image and pushing it somewhere to be available is simple.
speed: because all the deps are local there is no need for the build process to fetch anything from the internet.

###main drawback: maintenance
is that the image represents a snapshot in time of all your deps. so while its perfect for the build NOW, when you go forward and update or dependencies the docker image will miss them, causing your build tool to "miss" on the cache and go online to fetch them.

###how to overcome the drawback?
rebuild your image from time to time and push it to your favorite docker repository.
most CIs have a way to trigger a pipeline on some cron expression.
so you could automate the process by creating a small pipeline to get your code from your CVS (git master branch?), build the deps docker image and push it.

### how to build this image?

see Dockerfile for example, its a multi stage build:

```
docker build -t build-openjdk8-sbt-cached-deps -f Dockerfile .
```

- stage 1: some base docker image depending on your build env requiment (java? nodejs? python?) with the required build tools (sbt? nvm?)
- stage 2: based on stage 1, add the project files and run a full build (or just a deps fetch e.g. `npm i`), specifying the cache dirs for your build tool to some custom dir (/deps-cache in my file)
- stage 3: based on stage 1 (not 2!!), copying over all deps that were fetched from stage 2

what do we end with? a docker image that has the env + tools needed for the build & also the deps stored in /deps-cache

### how to use this image?

see `build-docker.sh` for example.
the build script should be run from within the docker image, with the project files present (mounted or git fetched) as well.
the build script simply calls your build tool specifying where the cache dirs are.



ARTIFACTORY
###########

artifactory will proxy & store all dependencies for you.
you just need to setup your build tool to look for deps on artifactory instead of wherever it looks for by default.

###main advantage: one time setup
once you setup your build to use artifactory, you generally don't need to maintain it anymore. unless you add dependencies from new repositories in which case you'll need to define these on your artifactory proxy.

###main disadvantage: speed
because the artifactory cache is not local to the build, it still needs to fetch from it, usually over network.


see `build-artifactory.sh` for example of using sbt+artifactory with credentials needed.
the credentials are fetched from vault. you can also jut read them from env (or god forbid hardcode then) if needed.
take a look at `plugins/plugins.sbt` and `build.sbt` to see how we define crentials for the different sbt stages. NOTICE that its dependant on a env var `CI` which generally should be easy to set for any CI system. you can also use another env var check if your CI system has one (or some) that are specific to your CI.