include project.cfg

DOCKER = DOCKER_BUILDKIT=1 docker
REQUIREMENTS = src/requirements*.txt
SOURCE = src/**

BUILD_DIR = .build

IMAGE_TAGS = latest $(tag) tools tests
IMAGES = $(foreach tag,$(IMAGE_TAGS),$(repo):$(tag))

# Runtime containers
CONTAINER_NAME = $(repo)
TEST_CONTAINER_NAME = debug-$(repo)
TOOL_CONTAINER_NAME = tools-$(repo)


default: build
.PHONY: FORCE clean build test debug format lint typecheck checks
FORCE:

# Utility rules
# -------------

# $(BUILD_DIR) is used for targets
clean:
	rm -Rf $(BUILD_DIR)
	docker rmi $(IMAGES)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)


# -- Vanilla Build Rules --
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
		$(repo):latest


# -- Testing Build Rules --
$(BUILD_DIR)/tests: Dockerfile $(REQUIREMENTS) | $(BUILD_DIR)
	$(DOCKER) build \
		--target=test \
		--tag=$(repo):tests \
		.
	touch $(BUILD_DIR)/tests

DOCKER_RUN_TESTS = $(DOCKER) run -it \
		--name="$(TEST_CONTAINER_NAME)" \
		--rm \
		--mount type=bind,source="$(PWD)/src",destination=/app\

debug: Dockerfile $(BUILD_DIR)/tests
	$(DOCKER_RUN_TESTS) \
		--entrypoint='' \
		$(repo):tests \
		bash

test: $(DOCKERFILE) $(BUILD_DIR)/tests
	$(DOCKER_RUN_TESTS) \
		$(repo):tests


# -- Tools build rules --
$(BUILD_DIR)/tools: Dockerfile tools.ini | $(BUILD_DIR)
	$(DOCKER) build \
		--target=tools \
		--tag="$(repo):tools" \
		. || exit 1
	touch $(BUILD_DIR)/tools


DOCKER_RUN_TOOLS = @ $(DOCKER) run -it \
		--name=$(TOOL_CONTAINER_NAME) \
		--rm \
		--mount type=bind,source="$(PWD)/src",destination=/app\
		"$(repo):tools"


format: $(BUILD_DIR)/tools
	@ echo -- Format --
	$(DOCKER_RUN_TOOLS) "black /app"


lint: $(BUILD_DIR)/tools
	@ echo -- Lint --
	$(DOCKER_RUN_TOOLS) flake8 --config=/root/tools.ini


typecheck: $(BUILD_DIR)/tools
	@ echo -- Typecheck --
	$(DOCKER_RUN_TOOLS) "mypy --config=/root/tools.ini ."

checks: format lint typecheck