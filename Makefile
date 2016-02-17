SHORT_NAME := slugrunner

export GO15VENDOREXPERIMENT=1

# Note that Minio currently uses CGO.

VERSION ?= 0.0.1-$(shell date "+%Y%m%d%H%M%S")
LDFLAGS := "-s -X main.version=${VERSION}"
BINDIR := ./rootfs/bin
DEV_REGISTRY ?= $$DEV_REGISTRY
DEIS_REGISTRY ?= ${DEV_REGISTRY}/
IMAGE_PREFIX ?= deis

IMAGE := ${DEIS_REGISTRY}${IMAGE_PREFIX}/${SHORT_NAME}:${VERSION}
POD := manifests/deis-slugrunner.yaml
SEC := manifests/deis-store-secret.yaml

all: build docker-build docker-push

bootstrap:
	@echo Nothing to do.

docker-build:
	docker build --rm -t temporal-slugrunner rootfs
	# These are both YAML specific
	# perl -pi -e "s|image: [a-z0-9.:]+\/deis\/${SHORT_NAME}:[0-9a-z-.]+|image: ${IMAGE}|g" ${RC}
	# perl -pi -e "s|release: [a-zA-Z0-9.+_-]+|release: ${VERSION}|g" ${RC}
	docker export `docker run -d --entrypoint /bin/bash temporal-slugrunner` | docker import - flat-image-name
	docker build -t ${IMAGE} .


docker-push:
	docker push ${IMAGE}

deploy: docker-build docker-push kube-pod

kube-pod: kube-service
	kubectl create -f ${POD}

kube-secrets:
	- kubectl -s http://172.17.8.102:8080 create -f ${SEC}

secrets:
	perl -pi -e "s|access-key-id: .+|access-key-id: ${key}|g" ${SEC}
	perl -pi -e "s|access-secret-key: .+|access-secret-key: ${secret}|g" ${SEC}
	echo ${key} ${secret}

kube-service: kube-secrets
	- kubectl create -f ${SVC}
	- kubectl create -f manifests/deis-minio-secretUser.yaml

kube-clean:
	- kubectl delete rc deis-${SHORT_NAME}-rc

test:
	@echo "Implement functional tests in _tests directory"

.PHONY: all bootstrap build docker-compile kube-up kube-down deploy test
