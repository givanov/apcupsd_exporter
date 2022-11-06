.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := build

APP_NAME := apcupsd_exporter

BINDIR := bin

LDFLAGS := -extldflags "-static"

BUILD_PATH = github.com/singularityconsulting/sparkpost-event-poller

GOLANGCI_LINT_VERSION := v1.37.1

HAS_GOX := $(shell command -v gox;)
HAS_GO_IMPORTS := $(shell command -v goimports;)
HAS_GO_MOCKGEN := $(shell command -v mockgen;)
HAS_GOLANGCI_LINT := $(shell command -v golangci-lint;)
GOLANGCI_VERSION_CHECK := $(shell golangci-lint --version | grep -oh $(GOLANGCI_LINT_VERSION);)
HAS_GO_BIN := $(shell command -v gobin;)
HAS_GCI := $(shell command -v gci;)
HAS_GO_FUMPT := $(shell command -v gofumpt;)

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
TARGETS   ?= darwin/amd64 linux/amd64 windows/amd64
TARGET_DIRS = find * -type d -exec

# Only set Version if building a tag or VERSION is set
ifneq ($(BINARY_VERSION),"")
	LDFLAGS += -X $(BUILD_PATH)/pkg/version.Version=$(VERSION)
	CHART_VERSION = $(VERSION)
endif

LDFLAGS += -X $(BUILD_PATH)/pkg/version.GitCommit=$(GIT_SHORT_COMMIT)

SHELL := /bin/bash

.PHONY: info
info:
	@echo "How are you:       $(GIT_DIRTY)"
	@echo "Version:           $(VERSION)"
	@echo "Git Tag:           $(GIT_TAG)"
	@echo "Git Commit:        $(GIT_SHORT_COMMIT)"
	@echo "binary:            $(BINARY_VERSION)"

build: clean-bin info bootstrap generate tidy fmt 
	@echo "build target..."
	@CGO_ENABLED=0 GOARCH=amd64 go build -o $(BINDIR)/$(APP_NAME) -ldflags '$(LDFLAGS)' ./cmd/apcupsd_exporter/main.go

.PHONY: build-cross
build-cross: clean bootstrap tidy generate fmt test
	CGO_ENABLED=0 gox -parallel=3 -output="$(DIST_DIR)/{{.OS}}-{{.Arch}}/$(APP_NAME)" -osarch='$(TARGETS)' -ldflags '$(LDFLAGS)' ./cmd/apcupsd_exporter/...

.PHONY: dist
dist: clean build-cross
	( \
		cd $(DIST_DIR) && \
		$(TARGET_DIRS) tar -zcf $(APP_NAME)-${VERSION}-{}.tar.gz {} \; && \
		$(TARGET_DIRS) zip -r $(APP_NAME)-${VERSION}-{}.zip {} \; \
	)

.PHONY: clean-bin
clean-bin: 
	@rm -rf $(BINDIR)

.PHONY: clean-dist
clean-dist:
	@rm -rf $(DIST_DIR)

.PHONY: clean
clean: clean-bin clean-dist

.PHONY: tidy
tidy:
	@echo "tidy target..."
	@go mod tidy

.PHONY: generate
generate: bootstrap
	@echo "generate target..."
	@rm -rf ./pkg/mocks
	@go generate ./...

.PHONY: vendor
vendor: tidy
	@echo "vendor target..."
	@go mod vendor

.PHONY: test
test: generate build
	@echo "test target..."
	@go test ./... -v -count=1

.PHONY: lint
lint: bootstrap bootstrap-lint build
	@echo "lint target..."
	@golangci-lint run --enable-all --disable lll,nakedret,funlen,gochecknoglobals,gomnd,wsl,errcheck,exhaustivestruct,gochecknoinits ./...

.PHONY: bootstrap-lint
bootstrap-lint:
	@echo "bootstrap lint..."
ifndef HAS_GOLANGCI_LINT
	@echo "golangci-lint $(GOLANGCI_LINT_VERSION) not found..."
	@gobin github.com/golangci/golangci-lint/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)
else
	@echo "golangci-lint found, checking version..."
ifeq ($(GOLANGCI_VERSION_CHECK), )
	@echo "found different version, installing golangci-lint $(GOLANGCI_LINT_VERSION)..."
	@gobin github.com/golangci/golangci-lint/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)
else
	@echo "golangci-lint version $(GOLANGCI_VERSION_CHECK) found!"
endif
endif

.PHONY: bootstrap
bootstrap: 
	@echo "bootstrap target..."
ifndef HAS_GO_BIN
	@GO111MODULE=off go get -u github.com/myitcv/gobin
endif
ifndef HAS_GO_IMPORTS
	@gobin golang.org/x/tools/cmd/goimports
endif
ifndef HAS_GO_MOCKGEN
	@go get -u github.com/golang/mock/gomock
	@gobin github.com/golang/mock/mockgen
endif
ifndef HAS_GOX
	@gobin github.com/mitchellh/gox
endif
ifndef HAS_GCI
	@gobin github.com/daixiang0/gci
endif
ifndef HAS_GO_FUMPT
	@gobin mvdan.cc/gofumpt
endif

.PHONY: fmt
fmt: bootstrap
	@echo "fmt target..."
	@gci -w $(SRC)
	@gofumpt -l -w $(SRC)

.PHONY: semantic-release
semantic-release:
	@npm ci
	@npx semantic-release

.PHONY: semantic-release-ci
semantic-release-ci:
	@npx semantic-release

.PHONY: semantic-release-dry-run
semantic-release-dry-run:
	@npm ci
	@npx semantic-release -d

.PHONY: install-npm-check-updates
install-npm-check-updates:
	npm install npm-check-updates

.PHONY: update-dependencies
update-dependencies: install-npm-check-updates
	ncu -u
	npm install

export-tag-github-actions:
	@echo "version=$(VERSION)" >> $${GITHUB_OUTPUT}