#!/usr/bin/env bash
cp ./docker/Dockerfile ./
docker buildx build . --output type=docker,name=elestio4test/taiga-backend:latest | docker load