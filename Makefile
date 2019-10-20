repo="template-project"
tag="0.1.0"
name="template-project"

DOCKER = DOCKER_BUILDKIT=1 docker
REQUIREMENTS = src/requirements*.txt
SOURCE = src/**


default: build
.PHONY: FORCE tools default build test test_build debug format lint typecheck
FORCE:

build: Dockerfile $(SOURCE)
	$(DOCKER) build \
		--tag $(repo):latest \
		--tag $(repo):$(tag) \
		.

run: build
	docker run --rm \
		--publish=5000:5000 \
		--name="$(name)" \
		"$(repo)":latest


test_build: Dockerfile $(REQUIREMENTS)
	debug_name="debug-$(name)"
	docker rm -f "$(debug_name)" > /dev/null 2>&1 || true

	$(DOCKER) build \
		--target=test \
		--tag="$(repo):tests" \
		. || exit 1


debug: Dockerfile test_build
	$(DOCKER) run -it \
		--name="$(debug_name)" \
		--mount type=bind,source="$(PWD)/src",destination=/app\
		--entrypoint='' \
		"$(repo)":tests \
		bash


test: $(DOCKERFILE) test_build
	$(DOCKER) run -it \
		--name="$(debug_name)" \
		--mount type=bind,source="$(PWD)/src",destination=/app\
		"$(repo)":tests

tools: Dockerfile
	tools_name=tools-$(name)
	$(DOCKER) build \
		--target=tools \
		--tag="$(repo):tools" \
		. || exit 1


format: tools
	$(DOCKER) run -it \
		--name="$(tools_name)" \
		--mount type=bind,source="$(PWD)/src",destination=/app\
		"$(repo)":tools \
		black /app/

lint: tools
	$(DOCKER) run -it \
		--name="$(tools_name)" \
		--mount type=bind,source="$(PWD)/src",destination=/app\
		"$(repo)":tools \
		flake8 --config=/root/tools.ini

typecheck: tools
	$(DOCKER) run -it \
		--name="$(tools_name)" \
		--mount type=bind,source="$(PWD)/src",destination=/app\
		"$(repo)":tools \
		mypy --config=/root/tools.ini .

