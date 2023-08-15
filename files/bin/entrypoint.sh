#!/bin/sh
set -e

# Run db setup if requested (possibly in addition to another command)
if [ "$GROUPER_INITDB" = "y" ] || [ "$1" = "initdb" ]; then
  echo "Initializing Grouper database using ./bin/gsh.sh -registry -runscript -noprompt"
  ./bin/gsh.sh -registry -runscript -noprompt
fi

if [ "$GROUPER_STARTQS" = "y" ] || [ "$1" = "startqs" ]; then
  echo "Starting up HSQL database with quickstart data"
  java -cp /opt/grouper.apiBinary-2.3.0/lib/jdbcSamples/hsqldb.jar org.hsqldb.Server -database.0 file:/opt/grouper.apiBinary-2.3.0/grouper -dbname.0 grouper -port 9001 &
fi

# Run the `command:`, `CMD`, or command-line command
case "$1" in
  initdb | startqs)
    # already done above
    exit 0
    ;;
  *)
    exec "$@"
    ;;
esac
