GOVERSION=$(shell go version)
GOOS=$(shell go env GOOS)
GOARCH=$(shell go env GOARCH)
VERSION=$(patsubst "%",%,$(lastword $(shell grep 'const Version' version.go)))
ARTIFACTS_DIR=artifacts/$(VERSION)
RELEASE_DIR=$(CURDIR)/release/$(VERSION)
SRC_FILES=$(shell find . -type f -name '*.go')
GITHUB_USERNAME=shogo82148

help: ## Show this text.
	# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: build-linux-amd64 build-darwin-amd64 ## Build binaries.

test: ## Run test.
	go test -v -race  -coverprofile=profile.cov -covermode=atomic ./...
	go vet ./...

clean: ## Remove built files.
	@rm -rf $(CURDIR)/artifacts
	@rm -rf $(CURDIR)/release

##### build settings

.PHONY: build build-linux-amd64 build-darwin-amd64


$(ARTIFACTS_DIR)/cloudwatch-logs-agent-lite_$(GOOS)_$(GOARCH):
	@mkdir -p $@

$(ARTIFACTS_DIR)/cloudwatch-logs-agent-lite_$(GOOS)_$(GOARCH)/cloudwatch-logs-agent-lite$(SUFFIX): $(ARTIFACTS_DIR)/cloudwatch-logs-agent-lite_$(GOOS)_$(GOARCH) $(SRC_FILES)
	@echo " * Building binary for $(GOOS)/$(GOARCH)..."
	@CGO_ENABLED=0 ./run-in-docker.sh go build -o $@ ./cmd/cloudwatch-logs-agent-lite

build: $(ARTIFACTS_DIR)/cloudwatch-logs-agent-lite_$(GOOS)_$(GOARCH)/cloudwatch-logs-agent-lite$(SUFFIX)

build-linux-amd64:
	@$(MAKE) build GOOS=linux GOARCH=amd64

build-darwin-amd64:
	@$(MAKE) build GOOS=darwin GOARCH=amd64


##### release settings

.PHONY: release-linux-amd64 release-darwin-amd64 release-linux-arm64
.PHONY: release-targz release-zip release-files release-upload

$(RELEASE_DIR)/cloudwatch-logs-agent-lite_$(GOOS)_$(GOARCH):
	@mkdir -p $@

release-linux-amd64:
	@$(MAKE) release-targz GOOS=linux GOARCH=amd64

release-linux-arm64:
	@$(MAKE) release-targz GOOS=linux GOARCH=arm64

release-darwin-amd64:
	@$(MAKE) release-targz GOOS=darwin GOARCH=amd64

release-targz: build $(RELEASE_DIR)/cloudwatch-logs-agent-lite_$(GOOS)_$(GOARCH)
	@echo " * Creating tar.gz for $(GOOS)/$(GOARCH)"
	tar -czf $(RELEASE_DIR)/cloudwatch-logs-agent-lite_$(GOOS)_$(GOARCH).tar.gz -C $(ARTIFACTS_DIR) cloudwatch-logs-agent-lite_$(GOOS)_$(GOARCH)

release-zip: build $(RELEASE_DIR)/cloudwatch-logs-agent-lite_$(GOOS)_$(GOARCH)
	@echo " * Creating zip for $(GOOS)/$(GOARCH)"
	cd $(ARTIFACTS_DIR) && zip -9 $(RELEASE_DIR)/cloudwatch-logs-agent-lite_$(GOOS)_$(GOARCH).zip cloudwatch-logs-agent-lite_$(GOOS)_$(GOARCH)/*

release-files: release-linux-amd64 release-darwin-amd64 release-linux-arm64

release-upload: release-files
	ghr -u $(GITHUB_USERNAME) --draft --replace v$(VERSION) $(RELEASE_DIR)
