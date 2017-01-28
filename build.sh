#!/usr/bin/env bash
set -o verbose
# DO NOT set -x: We do not want credentials in travis logs
# DO NOT set -e: We want to user travis's error handing

echo "TRAVIS_BRANCH: ${TRAVIS_BRANCH=this-is/fake-travis-branch}"

REPO=gehlenborglab/higlass-server
BRANCH=`echo ${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH} | perl -pne 'chomp;s{.*/}{};s/\W/-/g'`
echo "BRANCH: $BRANCH"

# TODO: Try to fill cache from dockerhub rather than starting from scratch.
# Not actually working for me: https://github.com/hms-dbmi/higlass-docker/issues/27
#- docker pull $REPO:$BRANCH || docker pull $REPO || true

STAMP=`date +"%Y-%m-%d_%H-%M-%S"`
docker build --tag image-$STAMP context

docker run --name container-$STAMP --detach --publish-all image-$STAMP
docker ps -a

PORT=`docker port container-2017-01-28_15-24-45 | perl -pne 's/.*://'`
URL=http://localhost:$PORT/api/v1/tilesets/

TRY=0;
until $(curl --output /dev/null --silent --fail --globoff $URL); do
    echo '.'
    (( TRY++ ))
    [[ $TRY -lt 10 ]] || break
    sleep 1
done

JSON=`curl $URL`
echo "API: $JSON"
HTML=`curl http://localhost:$PORT/`
echo "homepage: $HTML" | head -c 200

[ "$JSON" == '{"count": 0, "results": []}' ] \
    && ( echo $HTML | grep 'HiGlass' > /dev/null ) \
    && ( echo $HTML | grep 'Peter Kerpedjiev' > /dev/null ) \
    && ( echo $HTML | grep 'Department of Biomedical Informatics' > /dev/null ) \
    && echo "PASS"
