#!/usr/bin/env bash
set -e
set -v

STAMP=`date +"%Y-%m-%d_%H-%M-%S"`

# Run normal production script
./start_production.sh -s $STAMP -p 80 -v /data

# Set HiGlass.io
# 1. enable HiGlass.io homepage
docker exec -it container-$STAMP-with-redis sed -i 's/HGAC_HOMEPAGE_DEMOS=false/HGAC_HOMEPAGE_DEMOS=true/' higlass-app/config.js
