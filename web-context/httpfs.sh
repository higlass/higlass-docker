#! /usr/bin/env bash
ECHO "Mounting httpfs"
mkdir -p $HTTPFS_HTTP_DIR
mkdir -p $HTTPFS_HTTPS_DIR
mkdir -p $HTTPFS_FTP_DIR

simple-httpfs.py $HTTPFS_HTTPS_DIR --lru-capacity 1000 --disk-cache-dir /data/disk-cache --disk-cache-size 4294967296
simple-httpfs.py $HTTPFS_HTTP_DIR --lru-capacity 1000 --disk-cache-dir /data/disk-cache --disk-cache-size 4294967296
simple-httpfs.py $HTTPFS_FTP_DIR --lru-capacity 1000 --disk-cache-dir /data/disk-cache --disk-cache-size 4294967296
