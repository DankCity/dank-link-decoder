SHELL := /bin/bash

DOCKER_REPO := dankcity/dank-link-decoder
DOCKER_REPO_CI := dankcity/dank-link-decoder-ci
GIT_HASH = $(shell git rev-parse --short=7 HEAD)
GIT_TAG = $(shell git describe --tags --exact-match $(GIT_HASH) 2>/dev/null)

.PHONY: install-poetry
install-poetry:
	curl -sSL https://raw.githubusercontent.com/sdispater/poetry/master/get-poetry.py | python3

.PHONY: shell
shell:
	docker run --rm -it --entrypoint ash $(DOCKER_REPO):local

.PHONY: package
package: clean-dist clean-pkg
ifneq ($(CIRCLECI), )
	source $(HOME)/.poetry/env && poetry build --format sdist
else
	poetry build --format sdist
endif
	mkdir -p pkg
	find . -name "dank-link-decoder*.tar.gz" -exec tar --strip-components=1 -zxvf {} -C pkg \;

.PHONY: build
build:
	docker build -t $(DOCKER_REPO):local .

.PHONY: test
test: test-lint test-unit test-functional

.PHONY: test-lint
test-lint:
	docker run --rm -it \
		--entrypoint ash \
		$(DOCKER_REPO):local \
		-c ' \
			set -e; \
			pip install tox; \
			tox -e lint; \
		'

.PHONY: test-unit
test-unit:
	docker run --rm -it \
		--env-file <(env | grep -e "^CI") \
		--entrypoint ash \
		$(DOCKER_REPO):local \
		-c ' \
			set -e; \
			pip install tox; \
			tox -e unit; \
			if [ -n "$$CIRCLE_SHA1" ]; \
				then pip install codecov && codecov --commit=$$CIRCLE_SHA1; \
			fi \
		'

.PHONY: test-functional
test-functional:
	echo "Not yet enabled"
	# docker run --rm -it \
	# 	-w /clocme \
	# 	-v `pwd`:/clocme \
	# 	-v /var/run/docker.sock:/var/run/docker.sock \
	# 	-e IMAGE_NAME=$(DOCKER_REPO):local \
	# 	python:alpine \
	# 	ash -c ' \
	# 		set -e; \
	# 		pip install tox; \
	# 		tox -e functional \
	# 	'

.PHONY: tag-latest
tag-latest:
	docker tag $(DOCKER_REPO):local $(DOCKER_REPO):latest

.PHONY: tag-git-tag
tag-git-tag:
	docker tag $(DOCKER_REPO):$(GIT_HASH) $(DOCKER_REPO):$(GIT_TAG)

.PHONY: push-latest
push-latest:
	docker push $(DOCKER_REPO):latest

.PHONY: pull-latest
pull-latest:
	docker pull $(DOCKER_REPO):latest

.PHONY: tag-latest-as-local
tag-latest-as-local:
	docker tag $(DOCKER_REPO):latest $(DOCKER_REPO):local

.PHONY: push-tagged
push-tagged:
	docker push $(DOCKER_REPO):$(GIT_TAG)

.PHONY: push-ci
push-ci:
	docker tag $(DOCKER_REPO):local $(DOCKER_REPO_CI):$(GIT_HASH)
	docker push $(DOCKER_REPO_CI):$(GIT_HASH)

.PHONY: pull-ci
pull-ci:
	docker pull $(DOCKER_REPO_CI):$(GIT_HASH)
	docker tag $(DOCKER_REPO_CI):$(GIT_HASH) $(DOCKER_REPO):$(GIT_HASH)
	docker tag $(DOCKER_REPO_CI):$(GIT_HASH) $(DOCKER_REPO):local

.PHONY: clean-dist
clean-dist:
	rm -rf dist

.PHONY: clean-pkg
clean-pkg:
	rm -rf pkg
