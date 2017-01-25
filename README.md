# higlass-docker

Builds a docker container wrapping higlass-client and higlass-server in nginx,
tests that it works, and if there are no errors in the PR, pushes the image to 
[DockerHub](https://hub.docker.com/r/gehlenborglab/higlass-server/).

## Running locally

You can see HiGlass in action at [higlass.gehlenborglab.org](http://higlass.gehlenborglab.org/).

It is also easy to launch your own. Install Docker, and then:
```
docker pull gehlenborglab/higlass-server
docker run --detach --publish 8001:8000 gehlenborglab/higlass-server
```

Then visit [localhost:8001](http://localhost:8001/) in your browser.


## Running on AWS

First, install [aws-cli](https://aws.amazon.com/cli/) and 
[add your credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration).

Then, create your security group and key pair:
```bash
NAME=higlass-docker
aws ec2 create-security-group --group-name $NAME --description $NAME
aws ec2 authorize-security-group-ingress --group-name $NAME --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 create-key-pair --key-name $NAME --query 'KeyMaterial' --output text > $NAME.pem
chmod 400 $NAME.pem
```

TODO: Maybe there's an AMI optimized for Docker?

Then, create and connect to an EC2 instance:
```bash
GROUP_ID=`aws ec2 describe-security-groups --group-names $NAME --query 'SecurityGroups[0].GroupId' --output text`
INSTANCE_ID=`aws ec2 run-instances --image-id ami-29ebb519 --security-group-ids $GROUP_ID --count 1 --instance-type t2.micro --key-name devenv-key --query 'Instances[0].InstanceId' --output text`
```

It will need a moment to start, and then:
```bash
IP=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text`
ssh -i $NAME.pem ubuntu@$IP
```

TODO: Mount EBS volume? Or experiment with S3FS?

Once you've connected, launch docker as you would locally:
```
TODO
```

When you're done with the instance, clean up:
```
aws ec2 terminate-instances --instance-id $ID
aws ec2 delete-security-group --group-id $GROUP_ID
aws ec2 delete-key-pair --key-name $NAME
```



## Developing

To develop [higlass-client](https://github.com/hms-dbmi/higlass) and
[higlass-server](https://github.com/hms-dbmi/higlass-server),
check out the corresponding repos. 

To work on the Docker deployment, checkout this repo, install Docker, and then:

```bash
# build:
docker build --tag higlass-image .

# run:
#   Port 8000 is hardcoded in the image;
#   Port 8001 is what it should be mapped to on the host.
docker run --name higlass-container --detach --publish 8001:8000 higlass-image

# test:
curl http://localhost:8001/

# If that doesn't work, look at the logs:
docker logs higlass-container

# or connect to an already running container:
docker exec --interactive --tty higlass-container bash

# remove all containers (use with caution):
docker ps -a -q | xargs docker stop | xargs docker rm
```


## Releasing updates

TODO