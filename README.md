# higlass-docker

Builds a docker container wrapping higlass-client and higlass-server in nginx,
tests that it works, and if there are no errors in the PR, pushes the image to 
[DockerHub](https://hub.docker.com/r/gehlenborglab/higlass-server/).

## Running locally

You can see HiGlass in action at [higlass.gehlenborglab.org](http://higlass.gehlenborglab.org/).

It is also easy to launch your own. Install Docker, and then:
```
docker run --detach --publish 8001:8000 gehlenborglab/higlass-server
```

Then visit [localhost:8001](http://localhost:8001/) in your browser.


## Running on AWS

First, install [aws-cli](https://aws.amazon.com/cli/) and 
[add your credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration).
(For more help with this, see the [AWS documentation](http://docs.aws.amazon.com/cli/latest/userguide/tutorial-ec2-ubuntu.html).)

Then, create your security group and key pair:
```bash
NAME=higlass-docker
GROUP_NAME=${NAME}-group
aws ec2 create-security-group --group-name $GROUP_NAME --description $NAME
aws ec2 authorize-security-group-ingress --group-name $GROUP_NAME --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name $GROUP_NAME --protocol tcp --port 80 --cidr 0.0.0.0/0
KEY_NAME=${NAME}-key
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > ~/$KEY_NAME.pem
chmod 400 ~/$KEY_NAME.pem
```

Then, create an EC2 instance, and connect:
```bash
GROUP_ID=`aws ec2 describe-security-groups --group-names $GROUP_NAME --query 'SecurityGroups[0].GroupId' --output text`
INSTANCE_ID=`aws ec2 run-instances --image-id ami-29ebb519 --security-group-ids $GROUP_ID --count 1 --instance-type t2.micro --key-name $KEY_NAME --query 'Instances[0].InstanceId' --output text`
# Wait until it's "running":
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text
# and then:
IP=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text`
ssh -i ~/$KEY_NAME.pem ubuntu@$IP
```

Once you've connected, install docker as you would locally.
(For more help with these steps, see the
[Docker docs](https://docs.docker.com/engine/installation/linux/ubuntu/).)

SSH in, and then get the file system tools Docker needs:
```
sudo apt-get update
sudo apt-get install -y curl \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual
```
Add the Docker repo to apt-get:
```
sudo apt-get install apt-transport-https \
                       ca-certificates
curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -
# Verify the fingerprint:
apt-key finger | grep -A1 '5811 8E89 F3A9 1289 7C07  0ADB F762 2157 2C52 609D'
sudo add-apt-repository \
       "deb https://apt.dockerproject.org/repo/ \
       ubuntu-$(lsb_release -cs) \
       main"
```
And install docker itself:
```
sudo apt-get update
sudo apt-get -y install docker-engine
sudo docker run --detach --publish 80:8000 gehlenborglab/higlass-server
```

When you're done with the instance, clean up:
```
aws ec2 terminate-instances --instance-id $INSTANCE_ID
# Wait while instance terminates, and then
aws ec2 delete-security-group --group-id $GROUP_ID
aws ec2 delete-key-pair --key-name $KEY_NAME
rm ~/$KEY_NAME.pem
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

TODO!