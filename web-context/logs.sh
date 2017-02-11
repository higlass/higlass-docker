#!/usr/bin/env bash

for LOG in /tmp/*-std*.log /data/log/*.log; do
  echo; echo
  echo "############"
  echo $LOG
  echo "############"
  cat $LOG
done