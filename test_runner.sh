#!/usr/bin/env bash
set -e

export STAMP=`date +"%Y-%m-%d_%H-%M-%S"`

while getopts 's:w:l' OPT; do
  case $OPT in
    s)
      STAMP=$OPTARG
      ;;
  esac
done

echo "stamp:", $STAMP

./build.sh -w 4 -s $STAMP

perl -pne "s/<STAMP>/$STAMP/g" stack-template.yml > stack_test.yml

test_standalone() {
    # Keep this simple: We want folks just to be able to run the bare Docker container.
    # If this starts to get sufficiently complicated that we want to put it in a script
    # by itself, then it has gotten too complicated.
    docker-compose -f stack_test.yml down
    docker-compose -f stack_test.yml rm
    docker-compose -f stack_test.yml up -d
    python tests.py
}

test_standalone
