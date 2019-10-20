include project.cfg

DOCKER = DOCKER_BUILDKIT=1 docker
REQUIREMENTS = src/requirements*.txt
SOURCE = src/**

BUILD_DIR = .build

CONTAINER_NAME = $(repo)

default: build
.PHONY: FORCE clean default build test test_build debug format lint typecheck clean_tools_container
FORCE:

clean:
	rm -Rf $(BUILD_DIR)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)


$(BUILD_DIR)/build: Dockerfile $(SOURCE) | $(BUILD_DIR)
	$(DOCKER) build \
		--tag $(repo):latest \
		--tag $(repo):$(tag) \
		.
	touch $(BUILD_DIR)/build


build: $(BUILD_DIR)/build


run: $(BUILD_DIR)/build
	docker run --rm \
		--publish=5000:5000 \
		--name="$(CONTAINER_NAME)" \
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

tools_name=tools-$(repo)

$(BUILD_DIR)/tools: Dockerfile tools.ini | $(BUILD_DIR)
	$(DOCKER) build \
		--target=tools \
		--tag="$(repo):tools" \
		. || exit 1
	touch $(BUILD_DIR)/tools


# Command to run the tools image (Note: silent rule)

clean_tools_container:
	@ docker rm -f $(tools_name) > /dev/null 2>&1 || true

TOOLS_DOCKER_RUN = @ $(DOCKER) run -it \
		--name=$(tools_name) \
		--mount type=bind,source="$(PWD)/src",destination=/app\
		"$(repo)":tools


format: $(BUILD_DIR)/tools | clean_tools_container
	$(TOOLS_DOCKER_RUN) black /app/


lint: $(BUILD_DIR)/tools | clean_tools_container
	$(TOOLS_DOCKER_RUN) flake8 --config=/root/tools.ini


typecheck: $(BUILD_DIR)/tools | clean_tools_container
	$(TOOLS_DOCKER_RUN) mypy --config=/root/tools.ini .

