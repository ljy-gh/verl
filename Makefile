.PHONY: clean deepclean install dev constraints black mypy ruff toml-sort lint pre-commit test-run test build upload docs-autobuild changelog docs-gen docs-mypy docs-coverage docs

########################################################################################
# Variables
########################################################################################

# Define proxy settings to be used by all commands
export PIP_CACHE_DIR := /mnt/public/share/open_source_model/py_cache
export PIP_NO_CACHE_DIR := 0

# Determine whether to invoke pipenv based on CI environment variable and the availability of pipenv.
PIPRUN := $(shell [ "$$CI" != "true" ] && command -v pipenv > /dev/null 2>&1 && echo "pipenv run")
# PY := $(shell [ "$$CI" != "true" ] && echo "python3" || echo "/opt/python/3.10.13/bin/python3.10")
PY := python3
# Set the shell to bash for better compatibility.
SHELL := /bin/bash

# Get the Python version in `major.minor` format, using the environment variable or the virtual environment if exists.
PYTHON_VERSION := $(shell echo $${PYTHON_VERSION:-$$(python -V 2>&1 | cut -d ' ' -f 2)} | cut -d '.' -f 1,2)

# Determine the constraints file based on the Python version.
CONSTRAINTS_FILE := constraints/$(PYTHON_VERSION).txt

# Documentation target directory, will be adapted to specific folder for readthedocs.
PUBLIC_DIR := $(shell [ "$$READTHEDOCS" = "True" ] && echo "$$READTHEDOCS_OUTPUT/html" || echo "public")

# URL and Path of changelog source code.
CHANGELOG_URL := $(shell echo $${CI_PAGES_URL:-https://codeup.aliyun.com/deeplang/AI-Infra/lingo-engine.git}/_sources/changelog.md.txt)
CHANGELOG_PATH := docs/changelog.md

# package
PKGDIR := lingo
REPO_DIR_IN_DOCKER := $(shell cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
REPO_DIR := $(shell readlink -f $(REPO_DIR_IN_DOCKER))

CI ?= false


# docker version
DOCKER_VER := v1.8.7

# GIT related
COMMIT_ID := $(shell git rev-parse  --short=7 HEAD)
BRANCH_NAME := $(shell git rev-parse --abbrev-ref HEAD)
DATE := $(shell date +"%Y-%m-%d")

# docker settings
DOCKER_REGISTRY := 'uhub.service.ucloud.cn/deeplang-models'
DOCKER_IMAGE_TAG := $(subst /,-,$(BRANCH_NAME))-$(COMMIT_ID)-$(DATE)

########################################################################################
# Development Environment Management
########################################################################################

init-verl:
	if [ -z "$(LINGO_ENGINE_DOCKER_VERSION)" ]; then \
		echo "Please use LingoEngine Docker"; \
		exit 1; \
	fi

	if [ "$(CI)" != "true" ] ; then \
		[ -f Pipfile ] || pipenv && pipenv update setuptools==69.5.1; \
		git config --global --add safe.directory $(REPO_DIR); \
		echo "Set git proxy to 117.50.187.168:23451"; \
		git config --global http.proxy 117.50.187.168:23451; \
		echo "Detect not in CI"; \
	else \
		git config --global --add safe.directory $(REPO_DIR); \
		echo "Detect in CI"; \
	fi

	$(PIPRUN) pip3 config set global.extra-index-url https://mirrors.aliyun.com/pypi/simple/
	$(PIPRUN) pip3 config set global.trusted-host "tuna.tsinghua.edu.cn mirrors.aliyun.com"

dev-verl: init-verl
	$(PIPRUN) pip3 install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --no-index --find-links /mnt/public/share/open_source_model/whl_cache/torch-2.6.0-cu12.4
	$(PIPRUN) pip3 install /mnt/public/share/open_source_model/whl_cache/flash_attn-2.5.8-cp310-cp310-linux_x86_64.whl
	$(PIPRUN) pip3 install -e ./verl[gpu,test,sglang] -c constraints.txt --cache-dir ${PIP_CACHE_DIR}
	$(PIPRUN) pip3 install vllm==0.8.5 --cache-dir ${PIP_CACHE_DIR}
	$(PIPRUN) pip3 install -e /mnt/public/share/users/lijunyong-share/repositories/Flash-RL
	$(PIPRUN) pip3 install swanlab --cache-dir ${PIP_CACHE_DIR}