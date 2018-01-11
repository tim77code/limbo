ACCT_NAME := $(shell git remote get-url origin | sed 's|.*[:/]\([^:/]*\)/[^/]*$$|\1|')
export SERVICE_NAME ?= $(ACCT_NAME)

.PHONY: testall
testall: requirements
	tox

# to run a single file, with debugger support:
# pytest -s test/test_plugins/test_image.py
.PHONY: test
test: install
	LANG=en_US.UTF-8 pytest --cov=limbo --cov-report term-missing test

.PHONY: clean
clean:
	rm -rf build dist limbo.egg-info

.PHONY: run
run: install
	bin/limbo

.PHONY: repl
repl: install
	bin/limbo -t

.PHONY: requirements
requirements:
	pip install -r requirements.txt

.PHONY: install
install: requirements
	python setup.py install
	make clean

.PHONY: publish
publish:
	pandoc -s -w rst README.md -o README.rst
	python setup.py sdist upload
	rm README.rst

.PHONY: flake8
flake8:
	flake8 limbo test

.PHONY: docker_build
docker_build:
	docker build -f Dockerfile.test -t tim77/limbo-test .
	docker build --build-arg BASE=tim77/limbo-test -f Dockerfile.run -t tim77/limbo .

.PHONY: docker_test
docker_test:
	docker run -e LANG=en_US.UTF-8 tim77/limbo-test

.PHONY: docker_run
docker_run:
	@# Suppress echo so slack token does not get shown
	@docker run -e SLACK_TOKEN=${SLACK_TOKEN} tim77/limbo

.PHONY: docker_debug
docker_debug:
	@# Note: This command is insecure, because it emits SLACK_TOKEN to the terminal.
	docker run -e SLACK_TOKEN=${SLACK_TOKEN} -e LIMBO_LOGLEVEL=DEBUG tim77/limbo

.PHONY: docker_stop
docker_stop:
	docker stop `docker ps -q --filter ancestor=tim77/limbo --format="{{.ID}}"`

.PHONY: ecr_repo
ecr_repo:
	docker-compose -f cmds.yml run \
	   aws ecr create-repository --region us-east-1 --repository-name tim77/${SERVICE_NAME}

.PHONY: travis_deploy
travis_deploy:
	bin/deploy.sh update

.PHONY: ecs_start
ecs_start:
	bin/deploy.sh start

.PHONY: ecs_stop
ecs_stop:
	bin/deploy.sh stop
