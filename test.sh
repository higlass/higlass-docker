#!/usr/bin/env bash
set +o verbose # Less clutter at the start...

STAMP=$1
echo "STAMP: $STAMP"

# $PORT may be 0 if defaults were used, so we do need to look it up.
PORT=`docker port hg-container-$STAMP | perl -pne 's/.*://'`
URL=http://localhost:$PORT/api/v1/tilesets/

echo
echo "## TESTS ##"
echo
echo "If tests fail, or $URL doesn't work, try:"
echo "  docker exec --interactive --tty hg-container-$STAMP bash"

set +e # So we don't exit travis, instead of exiting the loop.
TRY=0;
until $(curl --output /dev/null --silent --fail --globoff $URL) || [[ $TRY -gt 10 ]]; do
    echo "try $TRY"
    (( TRY++ ))
    sleep 1
done
set -e

JSON=`curl -s $URL`
printf "\n\nAPI: \n$JSON"

HTML=`curl -s http://localhost:$PORT/`
printf "\n\nhomepage: \n$HTML" | head -c 200

NGINX_LOG=`docker logs nginx-container-$STAMP`
printf "\n\nnginx log: \n$NGINX_LOG"
# TODO: Make assertions against this.

echo
echo
set -o verbose # ... so we can see which one fails
[ "$JSON" == '{"count": 0, "results": []}' ]
echo $HTML | grep -o 'HiGlass'
echo $HTML | grep -o 'Peter Kerpedjiev'
echo $HTML | grep -o 'Department of Biomedical Informatics'
[ -z `echo $NGINX_LOG | grep -v '/api/v1/tilesets/'` ]

set +o verbose
echo
echo 'PASS!'
echo "  visit:   http://localhost:$PORT"
echo "  connect: docker exec --interactive --tty container-$STAMP bash"
