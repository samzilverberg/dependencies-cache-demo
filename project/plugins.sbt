val isInCI = System.getenv("CI") != null

credentials := {
  if (isInCI) {
    Seq(Credentials(new File(System.getenv("CREDS_FILE"))))
  } else {
    Seq()
  }
}


addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.6.18")
// plugin not used, jut added as an extra dep for cache
addSbtPlugin("com.timushev.sbt" % "sbt-updates" % "0.3.4")

