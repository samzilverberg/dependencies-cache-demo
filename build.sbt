name := """play-deps-cache-demo"""
organization := "com.samz"

version := "1.0-SNAPSHOT"

lazy val root = (project in file(".")).enablePlugins(PlayScala)

scalaVersion := "2.12.6"

val isInCI = System.getenv("CI") != null
Global / credentials ++= {
  if (isInCI) {
    Seq(Credentials(new File(System.getenv("CREDS_FILE"))))
  } else {
    Seq.empty
  }
}


libraryDependencies += guice
libraryDependencies += "org.scalatestplus.play" %% "scalatestplus-play" % "3.1.2" % Test

// Adds additional packages into Twirl
//TwirlKeys.templateImports += "com.samz.controllers._"

// Adds additional packages into conf/routes
// play.sbt.routes.RoutesKeys.routesImport += "com.samz.binders._"
