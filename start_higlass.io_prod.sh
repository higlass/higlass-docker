#!/usr/bin/env bash
set -e
set -v

STAMP=`date +"%Y-%m-%d_%H-%M-%S"`

# Run normal production script
./start_production.sh $STAMP

# Set HiGlass.io
# 1. copy config
docker exec -it container-$STAMP-with-redis cp higlass-app/config.json higlass-app/config.local.json
# 2. enable HiGlass.io homepage
docker exec -it container-$STAMP-with-redis sed -i 's/"homepageDemos": false/"homepageDemos": true/' higlass-app/config.local.json
