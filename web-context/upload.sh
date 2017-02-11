#!/usr/bin/env bash
set -e

while getopts 'c:u:' OPT; do
  case $OPT in
    c)
      CREDENTIALS=$OPTARG
      ;;
    u)
      URL=$OPTARG
      ;;
  esac
done

if [ -z $CREDENTIALS ] || [ -z $URL ]; then
  echo "USAGE: $0 -c CREDENTIALS -u URL" >&2
  exit 1
fi

set -o verbose

DOWNLOADS=/tmp/downloads
mkdir -p $DOWNLOADS
NAME=`basename $URL`
wget -O $DOWNLOADS/$NAME $URL

PORT=8000
# TODO: discrepancy?
# hgserver_nginx.conf: 8001
# uwsgi.ini: 8000

if [[ "$NAME" == *.cool ]]; then
    curl -F "datafile=@$DOWNLOADS/$NAME" -u "$CREDENTIALS" \
         -F "filetype=cooler" -F "datatype=matrix" -F "uid=cooler" \
         http://localhost:$PORT/api/v1/tilesets/
elif [[ "$NAME" == *.hitile ]]; then
    curl -F "datafile=@$DOWNLOADS/$HITILE" -u $USERNAME:$PASSWORD \
         -F "filetype=hitile" -F "datatype=vector" -F "uid=hitile" \
         http://localhost:$PORT/api/v1/tilesets/
else
    echo "Unrecognized file type: $NAME" >&2
    exit 1
fi