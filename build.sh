#!/usr/bin/env bash
set -o verbose
# DO NOT set -x: We do not want credentials in travis logs.
# DO NOT set -e: We want to use Travis's error handing.

echo "TRAVIS_BRANCH: ${TRAVIS_BRANCH=this-is/fake-travis-branch}"

REPO=gehlenborglab/higlass-server
BRANCH=`echo ${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH} | perl -pne 'chomp;s{.*/}{};s/\W/-/g'`
echo "BRANCH: $BRANCH"

# TODO: Try to fill cache from dockerhub rather than starting from scratch.
# Not actually working for me: https://github.com/hms-dbmi/higlass-docker/issues/27
#- docker pull $REPO:$BRANCH || docker pull $REPO || true

STAMP=`date +"%Y-%m-%d_%H-%M-%S"`
docker build --tag image-$STAMP context

VOLUME=/tmp/docker-volumes/volume-$STAMP
mkdir -p $VOLUME

docker run --name container-$STAMP --volume $VOLUME:/data --detach --publish-all image-$STAMP
docker ps -a

PORT=`docker port container-$STAMP | perl -pne 's/.*://'`
URL=http://localhost:$PORT/api/v1/tilesets/

TRY=0;
until $(curl --output /dev/null --silent --fail --globoff $URL); do
    echo '.'
    (( TRY++ ))
    [[ $TRY -lt 10 ]] || break
    sleep 1
done

JSON=`curl -s $URL`
echo "API: $JSON"
HTML=`curl -s http://localhost:$PORT/`
echo "homepage: $HTML" | head -c 200

[ "$JSON" == '{"count": 0, "results": []}' ] \
    && ( echo $HTML | grep -o 'HiGlass' ) \
    && ( echo $HTML | grep -o 'Peter Kerpedjiev' ) \
    && ( echo $HTML | grep -o 'Department of Biomedical Informatics' ) \
    && echo 'PASS!:' \
    && echo "  visit:   http://localhost:$PORT" \
    && echo "  connect: docker exec --interactive --tty container-$STAMP bash" \
    && echo "  volume:  $VOLUME"
