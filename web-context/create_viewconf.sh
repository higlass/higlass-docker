#!/usr/bin/env bash

# TODO: Let UID be set by user.
VIEWCONF=$1
VIEWCONFS_URL=http://localhost:80/api/v1/viewconfs/

JSON=`curl --globoff -s -H "Content-Type: application/json" -X POST -d "$VIEWCONF" $VIEWCONFS_URL`

echo $JSON | perl -pne 's/\{"uid": "//;s/"\}//'
# TODO: This is abhorrent! --> Redo this in Python.