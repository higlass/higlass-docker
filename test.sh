#!/usr/bin/env bash
set +o verbose # Less clutter at the start...

STAMP=$1

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
printf "\n\nAPI, tilesets: \n$JSON"

JSON_HITS_REDIS=`curl -s http://localhost:$PORT/api/v1/tiles/`
printf "\n\nAPI, tiles: \n$JSON_HITS_REDIS"

HTML=`curl -s http://localhost:$PORT/`
printf "\n\nhomepage: \n$HTML" | head -c 200

NGINX_LOG=`docker exec container-$STAMP cat /var/log/nginx/error.log`
printf "\n\nnginx log: \n$NGINX_LOG"
# TODO: Make assertions against this.

VERSION_TXT=`curl -s http://localhost:$PORT/version.txt`
printf "\n\nversion.txt: \n$VERSION_TXT"

echo
echo
set -o verbose # ... so we can see which one fails

[[ "$JSON" == '{"count":'* ]] # Redeploy a live server and there will be data already, but should start the same.
echo $HTML | grep -o 'HiGlass'
echo $HTML | grep -o 'Peter Kerpedjiev'
echo $HTML | grep -o 'Department of Biomedical Informatics'
[ -z `echo $NGINX_LOG | grep -v '/api/v1/tilesets/'` ]
#echo $PING_REDIS_INSIDE | grep -o 'PONG'
echo $VERSION_TXT | grep -o 'WEBSITE_VERSION'

if [[ "$STAMP" != *-single ]]; then
    # Only run these tests if we've started up a separate redis container.
    PING_REDIS_OUTSIDE=`docker exec container-$STAMP ping -c 1 container-redis-$STAMP`
    echo $PING_REDIS_OUTSIDE | grep -o '1 packets received, 0% packet loss'

    # TODO
    #PING_REDIS_INSIDE=`docker exec container-$STAMP sh -c '( echo PING | curl -v telnet://container-redis-$STAMP:6379 ) & sleep 1 ; kill $!'`
    #printf "\n\nping redis inside: \n$PING_REDIS_INSIDE"
    # -- OR --
    # `docker exec -it container-$STAMP sh -c "echo 'PING' | nc -w 1 container-redis-$STAMP 6379"`
    # but that requires the installation of netcat
    # -- OR --
    # exec 3<>/dev/tcp/container-redis-$STAMP/6379 && echo -e "PING\n\r" >&3 && cat <&3
    # which requires no installations, but it's crazy, and keeps the connection open.
    # -- OR --
    # install the Redis client
fi

set +o verbose
echo
echo 'PASS!'
echo "  visit:   http://localhost:$PORT"
echo "  connect: docker exec --interactive --tty container-$STAMP bash"
