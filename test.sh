#!/usr/bin/env bash
set +o verbose # Less clutter on test output

# $PORT may be 0 if defaults were used, so we do need to look it up.
PORT=`docker port container-$STAMP | perl -pne 's/.*://'`
URL=http://localhost:$PORT/api/v1/tilesets/

echo
echo "## TESTS ##"
echo
echo "If tests fail, or $URL doesn't work, try:"
echo "  docker exec --interactive --tty container-$STAMP bash"

set +e # So we don't exit travis, instead of exiting the loop.
TRY=0;
until $(curl --output /dev/null --silent --fail --globoff $URL) || [[ $TRY -gt 20 ]]; do
    echo "try $TRY"
    (( TRY++ ))
    sleep 1
done
set -e

JSON=`curl -s $URL`
echo "API: $JSON"

HTML=`curl -s http://localhost:$PORT/`
echo "homepage: $HTML" | head -c 200

NGINX_LOG=`docker exec container-$STAMP cat /var/log/nginx/error.log`
# TODO: Make assertions against this.

[ "$JSON" == '{"count": 0, "results": []}' ] \
    && ( echo $HTML | grep -o 'HiGlass' ) \
    && ( echo $HTML | grep -o 'Peter Kerpedjiev' ) \
    && ( echo $HTML | grep -o 'Department of Biomedical Informatics' ) \
    && ( docker exec container-$STAMP cat /var/log/nginx/error.log ) \
    && echo && echo 'PASS!' \
    && echo "  visit:   http://localhost:$PORT" \
    && echo "  connect: docker exec --interactive --tty container-$STAMP bash" \
    && echo "  volume:  $VOLUME" \
    && echo "  db:      $DB"
