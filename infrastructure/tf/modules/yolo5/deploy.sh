#!/bin/bash

apt-get update
apt-get install -y docker.io
apt-get install -y ansible
systemctl start docker
systemctl enable docker
echo $'{
  "storage-driver": "overlay"
}' > /etc/docker/daemon.json

systemctl restart docker
rm /etc/docker/daemon.json
export DOCKERLOGIN=$(/usr/local/bin/aws ecr get-login --region eu-north-1)
$(echo $DOCKERLOGIN)

docker pull ngnix

docker pull keretdodor/yolo5
docker run -d --restart always -e SQS_QUEUE_URL=${SQS_QUEUE_URL} -e DYNAMODB_TABLE_NAME=${DYNAMODB_TABLE_NAME} -e S3_BUCKET=${S3_BUCKET} -e ALIAS_RECORD=${ALIAS_RECORD} -e AWS_REGION=${AWS_REGION} keretdodor/yolo5

