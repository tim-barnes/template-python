# Template Project

## Purpose

This project provides a generic template for a dockerised python project.  It was written due to the following issues I regularly encountered in my working life and personal projects:

- Getting derailed mid flow due to needing to build a `Dockerfile`, install test tooling, or funny flake8 or mypy issues.  When I have an idea, I want to code, not spend ages setting up another project.
- Not having a standard approach.  By not reinventing the wheel every time I work on a new project, I should be able to reuse more of my experiments!
- Having a reference project that can be repurposed as required.


## Contents

* `src/` - Contains a simple "Hello World" application and unit test.  The contents of `src/` are mounted in the `/app` directory in the docker image.
  * `requirements.txt` - The runtime dependencies.
  * `requirements-test.txt` - Any test runtime dependencies.  Contains `pytest` and `ipdb` by default.
  * `app.py` - Main entrypoint.
  * `conftest.py` - Exists for pytest discovery.
  * `tests/` - Directory for tests.
* `Dockerfile` - Builds production, tools and tests images.
* `Makefile` - Make rules for running the project.
* `project.cfg` - Name and version for this project.
* `tools.ini` - Any custom configuration for the developer tools.


## Setup

1. Create a new repository, or a directory in an existing repository.
2. Copy all the files to the target directory.
3. Edit `project.cfg` to provide a unique name.
4. Code!

## Usage

All commands are run through `make`.  By default, make will build the project.  For example `make test` will run the unit tests.  The following commands are available:

### Build

* `build` - builds the image
* `run` - runs the image
* `clean` - cleans any build targets (including removing any built images)

### Test

All these commands mount the current `src/` instead of rebuilding the container.

* `test` - Run all the tests on the current code.
* `debug` - Open a bash shell in the test container.

### Tools

These are utility commands to aid development:

* `format` - Run `black` on the source tree.
* `lint` - Run `flake8` on the source tree.
* `typecheck` - Run `mypy` on the source tree
* `checks` - Run all the checks!


## Ideas to add later:

* Deployment - default helm chart and config.
* Docker compose - too many of my projects need other infrastructure.  A sensible default would be useful here.
* Integration tests - some default framework for more system wide testing.
