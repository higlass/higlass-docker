#! /usr/bin/env bash

if [ -z "$HTTPFS_HTTP_DIR" ]; then 
    HTTPFS_HTTP_DIR=/data/media/http
fi

if [ -z "$HTTPFS_HTTPS_DIR" ]; then 
    HTTPFS_HTTPS_DIR=/data/media/https
fi

if [ -z "$HTTPFS_FTP_DIR" ]; then 
    HTTPFS_FTP_DIR=/data/media/ftp
fi


mkdir -p $HTTPFS_HTTP_DIR
mkdir -p $HTTPFS_HTTPS_DIR
mkdir -p $HTTPFS_FTP_DIR

simple-httpfs.py $HTTPFS_HTTPS_DIR --lru-capacity 1000 --disk-cache-dir /data/disk-cache --disk-cache-size 4294967296
simple-httpfs.py $HTTPFS_HTTP_DIR --lru-capacity 1000 --disk-cache-dir /data/disk-cache --disk-cache-size 4294967296
simple-httpfs.py $HTTPFS_FTP_DIR --lru-capacity 1000 --disk-cache-dir /data/disk-cache --disk-cache-size 4294967296
