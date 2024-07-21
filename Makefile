.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := build

APP_NAME := apcupsd_exporter

BINDIR := bin

LDFLAGS := -extldflags "-static"

BUILD_PATH = github.com/givanov/apcupsd_exporter

SRC = $(shell find . -type f -name '*.go' -not -path "./vendor/*")

GIT_SHORT_COMMIT := $(shell git rev-parse --short HEAD)
GIT_TAG    := $(shell git describe --tags --abbrev=0 --exact-match 2>/dev/null)
GIT_DIRTY  = $(shell test -n "`git status --porcelain`" && echo "dirty" || echo "clean")

TMP_VERSION := canary

BINARY_VERSION := ""

ifndef VERSION
ifeq ($(GIT_DIRTY), clean)
ifdef GIT_TAG
	TMP_VERSION = $(GIT_TAG)
	BINARY_VERSION = $(GIT_TAG)
endif
endif
else
  BINARY_VERSION = $(VERSION)
endif

VERSION ?= $(TMP_VERSION)

DIST_DIR := _dist
TARGETS ?= darwin/amd64 linux/amd64 windows/amd64 linux/arm64
TARGET_DIRS = find * -type d -exec

# Only set Version if building a tag or VERSION is set
ifneq ($(BINARY_VERSION),"")
	LDFLAGS += -X $(BUILD_PATH)/pkg/version.Version=$(VERSION)
	CHART_VERSION = $(VERSION)
endif

GOARCH ?= amd64
GOOS ?= linux
LDFLAGS += -X $(BUILD_PATH)/pkg/version.GitCommit=$(GIT_SHORT_COMMIT)

SHELL := /bin/bash

.PHONY: info
info:
	@echo "How are you:       $(GIT_DIRTY)"
	@echo "Version:           $(VERSION)"
	@echo "Git Tag:           $(GIT_TAG)"
	@echo "Git Commit:        $(GIT_SHORT_COMMIT)"
	@echo "binary:            $(BINARY_VERSION)"

build: clean-bin info tidy fmt
	@echo "build target..."
	@CGO_ENABLED=0 GOARCH=$(GOARCH) GOOS=$(GOOS) go build -o $(BINDIR)/$(APP_NAME) -ldflags '$(LDFLAGS)' ./cmd/apcupsd_exporter/main.go

.PHONY: clean-bin
clean-bin: 
	@rm -rf $(BINDIR)


.PHONY: clean
clean: clean-bin

.PHONY: tidy
tidy:
	@echo "tidy target..."
	@go mod tidy

.PHONY: vendor
vendor: tidy
	@echo "vendor target..."
	@go mod vendor

.PHONY: test
test: build
	@echo "test target..."
	@go test ./... -v -count=1

.PHONY: fmt
fmt:
	@echo "fmt target..."
	@gofmt -l -w -s $(SRC)

# Semantic Release
.PHONY: semantic-release-dependencies
semantic-release-dependencies:
	@npm install --save-dev semantic-release
	@npm install @semantic-release/exec conventional-changelog-conventionalcommits -D

.PHONY: semantic-release
semantic-release: semantic-release-dependencies
	@npm ci
	@npx semantic-release

.PHONY: semantic-release-ci
semantic-release-ci: semantic-release-dependencies
	@npx semantic-release

.PHONY: semantic-release-dry-run
semantic-release-dry-run: semantic-release-dependencies
	@npm ci
	@npx semantic-release -d

export-tag-github-actions:
	@echo "version=$(VERSION)" >> $${GITHUB_OUTPUT}