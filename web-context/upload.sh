#!/usr/bin/env bash
set -e

trap 'pkill -P $$' EXIT # Kill the Django subprocess.

while getopts 'u:g:' OPT; do
  case $OPT in
    u)
      URL=$OPTARG
      ;;
    g)
      COORD=$OPTARG
      ;;
  esac
done

if [ -z $URL ] || [ -z $COORD ]; then
  echo "USAGE: $0 -u URL -g hg19" >&2
  exit 1
fi

set -o verbose

# TODO: Do we have a story yet where the user should care about this?
export USERNAME=username
export PASSWORD=password
/home/higlass/projects/create_user.sh
CREDENTIALS=$USERNAME:$PASSWORD

PORT=8888
python /home/higlass/projects/higlass-server/manage.py runserver localhost:$PORT &

TILESETS_URL=http://localhost:$PORT/api/v1/tilesets/

set +e # So we don't exit travis, instead of exiting the loop.
TRY=0;
until $(curl --output /dev/null --silent --fail --globoff $TILESETS_URL) || [[ $TRY -gt 20 ]]; do
    echo "try $TRY"
    (( TRY++ ))
    sleep 1
done
set -e

DOWNLOADS=/tmp/downloads
mkdir -p $DOWNLOADS
NAME=`basename $URL`
wget -O $DOWNLOADS/$NAME $URL

if [[ "$NAME" == *.cool ]]; then
    CMD="curl -F datafile=@$DOWNLOADS/$NAME -u $CREDENTIALS
              -F filetype=cooler -F datatype=matrix
              -F coordSystem=$COORD
              $TILESETS_URL"
elif [[ "$NAME" == *.hitile ]]; then
    CMD="curl -F datafile=@$DOWNLOADS/$NAME -u $CREDENTIALS
              -F filetype=hitile -F datatype=vector
              -F coordSystem=$COORD
              $TILESETS_URL"
else
    # TODO: Add other formats?
    echo "Unrecognized file type: $NAME" >&2
    exit 1
fi

echo $CMD
$CMD
