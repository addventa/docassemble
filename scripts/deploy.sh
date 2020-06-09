#!/bin/bash

SERVER_URL=$1
USERNAME=admin
TARGET_DIR=/home/admin/docassemble/

rsync -r --delete-after --exclude=README* --exclude=.git --exclude=scripts --quiet $TRAVIS_BUILD_DIR/ $USERNAME@$SERVER_URL:$TARGET_DIR
ssh -t $USERNAME@$SERVER_URL \
	'cd docassemble
	sudo docker rmi -f $(docker images | grep "^<none>" | awk "{print $3}")
	sudo docker build --tag docassemble_addventa:latest .
	sudo docker run -d -p 80:80 -p 443:443 --stop-timeout 600 docassemble_addventa:latest'