#!/usr/bin/env bash

STAMP=$1
echo "STAMP: $STAMP"
PORT=`docker port nginx-container-$STAMP | head -n1`
if [[ -z "$PORT" ]]; then
  echo "nginx-container-$STAMP has no open ports"
  exit 1
fi
echo "PORT: $PORT"
URL=http://localhost:$PORT/api/v1/tilesets/
echo "URL: $URL"

set +o verbose # Less clutter at the start...

echo
echo "## TESTS ##"
echo

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

PING_REDIS_OUTSIDE=`docker exec container-$STAMP ping -c 1 container-redis-$STAMP`
echo; echo # Was getting an error from printf about "\p". Weird.
echo "ping redis outside:"
echo $PING_REDIS_OUTSIDE

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

echo
echo
set -o verbose # ... so we can see which one fails
[ "$JSON" == '{"count": 0, "results": []}' ]
echo $HTML | grep -o 'HiGlass'
echo $HTML | grep -o 'Peter Kerpedjiev'
echo $HTML | grep -o 'Department of Biomedical Informatics'
[ -z `echo $NGINX_LOG | grep -v '/api/v1/tilesets/'` ]
echo $PING_REDIS_OUTSIDE | grep -o '1 packets received, 0% packet loss'
#echo $PING_REDIS_INSIDE | grep -o 'PONG'

set +o verbose
echo
echo 'PASS!'
echo "  visit:   http://localhost:$PORT"
echo "  connect: docker exec --interactive --tty container-$STAMP bash"
