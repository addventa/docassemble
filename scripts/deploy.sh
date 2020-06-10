#!/bin/bash

SERVER_URL=$1
USERNAME=ubuntu
TARGET_DIR=/home/ubuntu/docassemble/

rsync -r --delete-after --exclude=.git --exclude=scripts --quiet $TRAVIS_BUILD_DIR/ $USERNAME@$SERVER_URL:$TARGET_DIR
ssh -t $USERNAME@$SERVER_URL \
	'cd docassemble
	DOCKER_STOP=$(docker ps -aq)
	sudo docker stop ${DOCKER_STOP}
	sudo docker rmi -f $(docker images | grep "^<none>" | awk "{print $3}")
	sudo docker build --tag docassemble_addventa:latest .
	sudo docker run -d -p 80:80 -p 443:443 --stop-timeout 600 docassemble_addventa:latest'