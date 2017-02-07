#!/usr/bin/env bash
set -o verbose
set -e


NAME=higlass-docker
GROUP_NAME=${NAME}-group
KEY_NAME=${NAME}-key


GROUP_ID=`aws ec2 describe-security-groups \
          --group-names $GROUP_NAME \
          --query 'SecurityGroups[0].GroupId' \
          --output text`

echo "GROUP_ID: $GROUP_ID"

INSTANCE_ID=`aws ec2 run-instances \
          --image-id ami-e13739f6 \
          --security-group-ids $GROUP_ID \
          --count 1 \
          --instance-type t2.medium \
          --key-name $KEY_NAME \
          --query 'Instances[0].InstanceId' \
          --placement AvailabilityZone=us-east-1c \
          --output text`

echo "INSTANCE_ID: $INSTANCE_ID"

aws ec2 create-tags \
    --resources ${INSTANCE_ID} \
    --tags Key=Name,Value=higlass-server \
           Key=owner,Value=pkerp

status() {
    aws ec2 describe-instances \
        --instance-ids $1 \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text
}

set +e
TRY=0;
until [[ `status $INSTANCE_ID` == 'running' ]] || [[ $TRY -gt 20 ]]; do
    echo "try $TRY"
    (( TRY++ ))
    sleep 1
done
set -e

# and then:
IP=`aws ec2 describe-instances \
     --instance-ids $INSTANCE_ID \
     --query 'Reservations[0].Instances[0].PublicIpAddress' \
     --output text`

echo "IP: $IP"

# create mount point
ssh -i ~/$KEY_NAME.pem ubuntu@$IP 'sudo mkdir /data'

