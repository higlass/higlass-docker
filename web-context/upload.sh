#!/usr/bin/env bash
set -e

while getopts 'c:u:g:' OPT; do
  case $OPT in
    c)
      CREDENTIALS=$OPTARG
      ;;
    u)
      URL=$OPTARG
      ;;
    g)
      COORD=$OPTARG
      ;;
  esac
done

if [ -z $CREDENTIALS ] || [ -z $URL ] || [ -z $COORD ]; then
  echo "USAGE: $0 -c CREDENTIALS -u URL -g hg19" >&2
  exit 1
fi

set -o verbose

PORT=8888
python /home/higlass/projects/higlass-server/manage.py runserver localhost:$PORT &

# TODO: explicitly wait for server to start

DOWNLOADS=/tmp/downloads
mkdir -p $DOWNLOADS
NAME=`basename $URL`
wget -O $DOWNLOADS/$NAME $URL

# TODO: Is coordSystem required? Should it be a parameter?

if [[ "$NAME" == *.cool ]]; then
    CMD="curl -F datafile=@$DOWNLOADS/$NAME -u $CREDENTIALS
              -F filetype=cooler -F datatype=matrix
              -F coordSystem=$COORD
              http://localhost:$PORT/api/v1/tilesets/"
elif [[ "$NAME" == *.hitile ]]; then
    CMD="curl -F datafile=@$DOWNLOADS/$NAME -u $CREDENTIALS
              -F filetype=hitile -F datatype=vector
              -F coordSystem=$COORD
              http://localhost:$PORT/api/v1/tilesets/"
else
    # TODO: Add other formats?
    echo "Unrecognized file type: $NAME" >&2
    exit 1
fi

echo $CMD
$CMD