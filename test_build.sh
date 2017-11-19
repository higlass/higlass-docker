#!/usr/bin/env bash

docker stop cont-$1
docker rm cont-$1

./build.sh -w 4 -s $1

docker run -d --name cont-$1 -p 8888:80 image-$1
