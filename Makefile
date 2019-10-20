include project.cfg

DOCKER = DOCKER_BUILDKIT=1 docker
REQUIREMENTS = src/requirements*.txt
SOURCE = src/**

BUILD_DIR = .build

CONTAINER_NAME = $(repo)
TEST_CONTAINER_NAME = debug-$(repo)
TOOL_CONTAINER_NAME = tools-$(repo)

CONTAINERS = $(CONTAINER_NAME) $(TEST_CONTAINER_NAME) $(TOOL_CONTAINER_NAME)

default: build
.PHONY: FORCE clean default build test test_build debug format lint typecheck clean_docker_containers
FORCE:

# Utility rules
# -------------

# $(BUILD_DIR) is used for targets
clean:
	rm -Rf $(BUILD_DIR)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

clean_docker_containers: clean_tools_containers clean_test_containers
	@ docker rm -f $(CONTAINER_NAME) > /dev/null 2>&1 || true


# Plain Build Rules
# -----------------
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


# -- Testing Build Rules --
clean_test_containers:
	@ docker rm -f $(TEST_CONTAINER_NAME) > /dev/null 2>&1 || true

$(BUILD_DIR)/tests: Dockerfile $(REQUIREMENTS) | $(BUILD_DIR)
	$(DOCKER) build \
		--target=test \
		--tag="$(repo):tests" \
		.


debug: Dockerfile $(BUILD_DIR)/tests | clean_test_containers
	$(DOCKER) run -it \
		--name="$(TEST_CONTAINER_NAME)" \
		--mount type=bind,source="$(PWD)/src",destination=/app\
		--entrypoint='' \
		"$(repo)":tests \
		bash


test: $(DOCKERFILE) $(BUILD_DIR)/tests | clean_test_containers
	$(DOCKER) run -it \
		--name="$(TEST_CONTAINER_NAME)" \
		--mount type=bind,source="$(PWD)/src",destination=/app\
		"$(repo)":tests


# -- Tools build rules --
$(BUILD_DIR)/tools: Dockerfile tools.ini | $(BUILD_DIR)
	$(DOCKER) build \
		--target=tools \
		--tag="$(repo):tools" \
		. || exit 1
	touch $(BUILD_DIR)/tools

clean_tools_containers:
	@ docker rm -f $(TOOL_CONTAINER_NAME) > /dev/null 2>&1 || true

TOOLS_DOCKER_RUN = @ $(DOCKER) run -it \
		--name=$(TOOL_CONTAINER_NAME) \
		--mount type=bind,source="$(PWD)/src",destination=/app\
		"$(repo)":tools


format: $(BUILD_DIR)/tools | clean_tools_containers
	$(TOOLS_DOCKER_RUN) black /app/


lint: $(BUILD_DIR)/tools | clean_tools_containers
	$(TOOLS_DOCKER_RUN) flake8 --config=/root/tools.ini


typecheck: $(BUILD_DIR)/tools | clean_tools_containers
	$(TOOLS_DOCKER_RUN) mypy --config=/root/tools.ini .

