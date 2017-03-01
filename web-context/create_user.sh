#!/usr/bin/env bash

# TODO: We needed for an earlier workflow, but nothing references it now. Remove?

if [ -z $USERNAME ] || [ -z $PASSWORD ]; then
  echo "USERNAME and PASSWORD envvars must be set" >&2
  exit 1
fi

echo "import django.contrib.auth; django.contrib.auth.models.User.objects.create_user('$USERNAME', password='$PASSWORD')" \
     | python /home/higlass/projects/higlass-server/manage.py shell