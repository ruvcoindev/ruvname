ROOT:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
IMAGE_NAME:=ruvname

build:
	docker build -t ${IMAGE_NAME} .
