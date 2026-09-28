#!/usr/bin/env bash
# 生成 build/mycpu_top.v，打上时序补丁得到 build/core_top.v
set -euo pipefail
cd "$(dirname "$0")"
J=${JAVA:-java}
jv=$("$J" -version 2>&1 | sed -E -n '1s/.*version "([0-9]+).*/\1/p')
# Scala 2.12.16 在 17 以上的 JDK 里崩，栈里看不出是版本的事
[ "${jv:-0}" -le 17 ] || { echo "要 JDK 17 或更早，$J 是 $jv；设 JAVA 指向它" >&2; exit 1; }
if [ -z "${SBT:-}" ] && ! command -v sbt > /dev/null; then
  v=$(sed -n 's/^sbt.version=//p' project/build.properties)
  j=target/sbt-launch-$v.jar
  mkdir -p target
  [ -s "$j" ] || curl -fsSL -o "$j" "https://repo1.maven.org/maven2/org/scala-sbt/sbt-launch/$v/sbt-launch-$v.jar"
  SBT="$J -jar $j"
fi
${SBT:-sbt} "runMain NOP.Main"
patch --fuzz=0 -o build/core_top.v build/mycpu_top.v < timing-surgery.patch
