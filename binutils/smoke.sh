#!/bin/sh
set -eu

if [ $# -ne 2 ]; then
    echo "usage: $0 <launch4j.jar> <outdir>" >&2
    exit 2
fi
JAR=$1
OUT=$2
SOURCE_DATE_EPOCH=$(git log -1 --no-show-signature --pretty=%ct)
export SOURCE_DATE_EPOCH

mkdir -p "$OUT"
cp demo/ConsoleApp/ConsoleApp.jar demo/ConsoleApp/l4j/ConsoleApp.ico \
    demo/SimpleApp/SimpleApp.jar demo/SimpleApp/l4j/SimpleApp.ico demo/SimpleApp/l4j/splash.bmp "$OUT"

exe() {
    cat > "$OUT/$1.xml" <<EOF
<launch4jConfig>
  <headerType>$2</headerType>
  <jar>$3.jar</jar>
  <outfile>$1.exe</outfile>
  <errTitle>$3</errTitle>
  <icon>$3.ico</icon>
  <jre>
    <path>$4</path>
    <minVersion>1.8.0</minVersion>
  </jre>
  $5
</launch4jConfig>
EOF
    java -jar "$JAR" "$OUT/$1.xml"
}

exe console console ConsoleApp '%JAVA_HOME%;%PATH%' ''
exe console-jre console ConsoleApp jre ''
exe console-reg console ConsoleApp nonexistent ''
exe gui gui SimpleApp '%JAVA_HOME%;%PATH%' \
    '<splash><file>splash.bmp</file><waitForWindow>true</waitForWindow><timeout>60</timeout><timeoutErr>true</timeoutErr></splash>'
