#!/usr/bin/env bash
set -o verbose
set -e
# DO NOT set -x: We do not want credentials in travis logs.

error_report() {
  docker logs container-$STAMP
}

trap 'error_report' ERR

if [ -z "$TRAVIS_BRANCH" ]; then
  TRAVIS_BRANCH=`git status --porcelain --branch | grep '##' | perl -pne 's/.* //'`
fi
echo "TRAVIS_BRANCH: $TRAVIS_BRANCH"

REPO=gehlenborglab/higlass-server
BRANCH=`echo ${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH} | perl -pne 'chomp;s{.*/}{};s/\W/-/g'`
echo "BRANCH: $BRANCH"

STAMP=`date +"%Y-%m-%d_%H-%M-%S"`
docker pull $REPO:latest
docker build --cache-from $REPO:latest \
             --build-arg WORKERS=2 \
             --tag image-$STAMP \
             context

VOLUME=/tmp/higlass-docker/volume-$STAMP
mkdir -p $VOLUME
DB=/tmp/higlass-docker/db-$STAMP.sqlite3
touch $DB
docker run --name container-$STAMP \
           --volume $VOLUME:/home/higlass/projects/higlass-server/data \
           --volume $DB:/home/higlass/projects/higlass-server/db.sqlite3 \
           --detach --publish-all image-$STAMP
docker ps -a

PORT=`docker port container-$STAMP | perl -pne 's/.*://'`
URL=http://localhost:$PORT/api/v1/tilesets/

echo "If $URL doesn't work, try:"
echo "  docker exec --interactive --tty container-$STAMP bash"

set +e
TRY=0;
until $(curl --output /dev/null --silent --fail --globoff $URL) || [[ $TRY -gt 20 ]]; do
    echo "try $TRY"
    echo 'increment?'
    (( TRY++ ))
    echo 'sleep?'
    sleep 1
    echo 'next?'
done
set -e

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
    && echo "  volume:  $VOLUME" \
    && echo "  db:      $DB"
