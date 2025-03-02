#!/bin/bash

docker stop -t 300 execution
docker stop -t 180 beacon

sudo docker container prune -f 
