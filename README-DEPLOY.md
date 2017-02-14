
# higlass-docker: Deployment

The following describes setup instructions for a linux machine running ubuntu.

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
```

Finally, call our script to setup all the containers.
```
curl https://raw.githubusercontent.com/hms-dbmi/higlass-docker/master/start_production.sh | bash
```

When you're done with the instance, clean up:
```
aws ec2 terminate-instances --instance-id $INSTANCE_ID
# Wait while instance terminates, and then
aws ec2 delete-security-group --group-id $GROUP_ID
aws ec2 delete-key-pair --key-name $KEY_NAME
rm ~/$KEY_NAME.pem
```
