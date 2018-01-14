/usr/bin/time ./build.sh -w 2

docker login --username=pkerpedjiev --password-stdin < ~/.docker-password
docker tag image-default pkerpedjiev/higlass:test
docker push pkerpedjiev/higlass:test
