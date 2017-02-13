#!/usr/bin/env bash
set +o verbose # Less clutter at the start...

STAMP=$1
SUFFIX=$2

PORT=`docker port container-$STAMP$SUFFIX | perl -pne 's/.*://'`
TILESETS_URL=http://localhost:$PORT/api/v1/tilesets/

echo
echo "## TEST: $STAMP$SUFFIX ##"
echo
echo "If tests fail, or $TILESETS_URL doesn't work, try:"
echo "  docker exec --interactive --tty container-$STAMP$SUFFIX bash"

set +e # So we don't exit travis, instead of exiting the loop.
TRY=0;
until $(curl --output /dev/null --silent --fail --globoff $TILESETS_URL) || [[ $TRY -gt 20 ]]; do
    echo "try $TRY"
    (( TRY++ ))
    sleep 1
done
set -e

JSON=`curl -s $TILESETS_URL`
printf "\n\nAPI, tilesets: \n$JSON"

JSON_HITS_REDIS=`curl -s http://localhost:$PORT/api/v1/tiles/`
printf "\n\nAPI, tiles: \n$JSON_HITS_REDIS"

HTML=`curl -s http://localhost:$PORT/`
printf "\n\nhomepage: \n$HTML" | head -c 200

NGINX_LOG=`docker exec container-$STAMP$SUFFIX cat /var/log/nginx/error.log`
printf "\n\nnginx log: \n$NGINX_LOG"
# TODO: Make assertions against this.

VERSION_TXT=`curl -s http://localhost:$PORT/version.txt`
printf "\n\nversion.txt: \n$VERSION_TXT"

echo
echo
set -o verbose # ... so we can see which one fails

# TODO: Clean up tests... Maybe translate whole thing to Python...

[[ "$JSON" == '{"count":'* ]] || false # Redeploy a live server and there will be data already, but should start the same.
echo $HTML | grep -o 'HiGlass'
echo $HTML | grep -o 'Peter Kerpedjiev'
echo $HTML | grep -o 'Department of Biomedical Informatics'
[ -z `echo $NGINX_LOG | grep -v '/api/v1/tilesets/'` ] || false
#echo $PING_REDIS_INSIDE | grep -o 'PONG'
echo $VERSION_TXT | grep -o 'WEBSITE_VERSION'
if [ -e /tmp/higlass-docker/volume-$STAMP ]; then
    diff -y expected-data-dir.txt <(
            pushd /tmp/higlass-docker/volume-$STAMP > /dev/null \
            && find . | sort | perl -pne 's/-\w+\.log/-XXXXXX.log/' \
            && popd > /dev/null )
fi


S3=https://s3.amazonaws.com/pkerp/public
COOLER=dixon2012-h1hesc-hindiii-allreps-filtered.1000kb.multires.cool
docker exec -it container-$STAMP$SUFFIX ./upload.sh -u $S3/$COOLER -g hg19
curl $TILESETS_URL | grep -o $COOLER

#HITILE=wgEncodeCaltechRnaSeqHuvecR1x75dTh1014IlnaPlusSignalRep2.hitile
#docker exec -it container-$STAMP ./upload.sh  -u $S3/$HITILE -g hg19
#curl $TILESETS_URL | grep -o $HITILE


if [[ "$SUFFIX" != '-standalone' ]]; then
    # Only run these tests if we've started up a separate redis container.
    PING_REDIS_OUTSIDE=`docker exec container-$STAMP$SUFFIX ping -c 1 container-redis-$STAMP`
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
echo "  connect: docker exec --interactive --tty container-$STAMP$SUFFIX bash"
