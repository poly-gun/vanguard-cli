# ====================================================================================
# Project Specific Globals
# ------------------------------------------------------------------------------------
#
# - It's assumed the $(name) is the same literal as the compiled binary.
# - Override the defaults if not available in a pipeline's environment variables.
#
# - Default GitHub environment variables: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/store-information-in-variables#default-environment-variables

name := vanguard
ifdef CI_PROJECT_NAME
    override name = $(CI_PROJECT_NAME)
endif

homebrew-tap := poly-gun/vanguard-cli
ifdef HOMEBREW_TAP
    override homebrew-tap = $(HOMEBREW_TAP)
endif

# homebrew-tap-repository := gitlab.com:example-organization/group-1/group-2/homebrew-taps.git
homebrew-tap-repository := https://github.com/poly-gun/homebrew-taps
ifdef HOMEBREW_TAP_REPOSITORY
    override homebrew-tap-repository = $(HOMEBREW_TAP_REPOSITORY)
endif

type := patch
ifdef RELEASE_TYPE
    override type = RELEASE_TYPE
endif

# type-title := $(shell echo $(tr '[:lower:]' '[:upper:]' <<< ${type:0:1})${type:1})
type-title = $(shell printf "%s" "$(shell tr '[:lower:]' '[:upper:]' <<< "$(type)")")

ifeq (,$(shell go env GOBIN))
	GOBIN=$(shell go env GOPATH)/bin
else
	GOBIN=$(shell go env GOBIN)
endif

# Setting SHELL to bash allows bash commands to be executed by recipes.
SHELL = /usr/bin/env bash -o pipefail

.SHELLFLAGS = -ec

# ====================================================================================
# Colors
# ------------------------------------------------------------------------------------

black        := $(shell printf "\033[30m")
black-bold   := $(shell printf "\033[30;1m")
red          := $(shell printf "\033[31m")
red-bold     := $(shell printf "\033[31;1m")
green        := $(shell printf "\033[32m")
green-bold   := $(shell printf "\033[32;1m")
yellow       := $(shell printf "\033[33m")
yellow-bold  := $(shell printf "\033[33;1m")
blue         := $(shell printf "\033[34m")
blue-bold    := $(shell printf "\033[34;1m")
magenta      := $(shell printf "\033[35m")
magenta-bold := $(shell printf "\033[35;1m")
cyan         := $(shell printf "\033[36m")
cyan-bold    := $(shell printf "\033[36;1m")
white        := $(shell printf "\033[37m")
white-bold   := $(shell printf "\033[37;1m")
reset        := $(shell printf "\033[0m")

# ====================================================================================
# Logger
# ------------------------------------------------------------------------------------

time-long	= $(date +%Y-%m-%d' '%H:%M:%S)
time-short	= $(date +%H:%M:%S)
time		= $(time-short)

information	= echo $(time) $(green)[ INFO ]$(reset)
debug	= echo $(time) $(blue)[ DEBUG ]$(reset)
warning	= echo $(time) $(yellow)[ WARNING ]$(reset)
exception		= echo $(time) $(red)[ ERROR ]$(reset)
complete		= echo $(time) $(white)[ COMPLETE ]$(reset)
fail	= (echo $(time) $(red)[ FAILURE ]$(reset) && false)

# ====================================================================================
# Utility Command(s)
# ------------------------------------------------------------------------------------

url = $(shell git config --get remote.origin.url | sed -r 's/.*(\@|\/\/)(.*)(\:|\/)([^:\/]*)\/([^\/\.]*)\.git/https:\/\/\2\/\4\/\5/')

repository = $(shell basename -s .git $(shell git config --get remote.origin.url))
organization = $(shell git remote -v | grep "(fetch)" | sed 's/.*\/\([^ ]*\)\/.*/\1/')
package = $(shell git remote -v | grep "(fetch)" | sed 's/^origin[[:space:]]*//; s/[[:space:]]*(fetch)$$//' | sed 's/https:\/\///; s/git@//; s/\.git$$//; s/:/\//' | sed -E 's|^ssh/+||')

version = $(shell [ -f VERSION ] && head VERSION || echo "0.0.0")

major      		= $(shell echo $(version) | sed "s/^\([0-9]*\).*/\1/")
minor      		= $(shell echo $(version) | sed "s/[0-9]*\.\([0-9]*\).*/\1/")
patch      		= $(shell echo $(version) | sed "s/[0-9]*\.[0-9]*\.\([0-9]*\).*/\1/")

zero = $(shell printf "%s" "0")

major-upgrade 	= $(shell expr $(major) + 1).$(zero).$(zero)
minor-upgrade 	= $(major).$(shell expr $(minor) + 1).$(zero)
patch-upgrade 	= $(major).$(minor).$(shell expr $(patch) + 1)

dirty = $(shell git diff --quiet)
dirty-contents 			= $(shell git diff --shortstat 2>/dev/null 2>/dev/null | tail -n1)

# ====================================================================================
# Build Command(s)
# ------------------------------------------------------------------------------------

compile = go build --mod "vendor" --ldflags "-s -w -X=main.version=$(tag) -X=main.date=$(shell date +%Y-%m-%d:%H-%M-%S) -X=main.source=false" -o "./build/$(name)-$(GOOS)-$(GOARCH)/$(name)"
compile-windows = go build --mod "vendor" --ldflags "-s -w -X=main.version=$(tag) -X=main.date=$(shell date +%Y-%m-%d:%H-%M-%S) -X=main.source=false" -o "./build/$(name)-$(GOOS)-$(GOARCH)/$(name).exe"

archive = tar -czvf "$(name)-$(GOOS)-$(GOARCH).tar.gz" -C "./build/$(name)-$(GOOS)-$(GOARCH)" .
archive-windows = cd "./build/$(name)-$(GOOS)-$(GOARCH)" && zip -r "../../$(name)-$(GOOS)-$(GOARCH).zip" "." && cd -

distribute = mkdir -p distribution && mv *.tar.gz distribution
distribute-windows = mkdir -p distribution && mv *.zip distribution

# ====================================================================================
# Default
# ------------------------------------------------------------------------------------

# all :: pre-requisites prepare test-release release overwrite-private-homebrew-download-strategy install

all :: pre-requisites prepare test-release release install

# ====================================================================================
# Pre-Requisites
# ------------------------------------------------------------------------------------

tools:
	@printf "$(green-bold)%s$(reset)\n" "Installing Latest Tools"
	@go get -u -tool golang.org/x/tools/cmd/stringer@latest
	@go get -u -tool golang.org/x/tools/cmd/goimports@latest

pre-requisites: tools
	@command -v brew 2>&1> /dev/null || bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	@command -v goreleaser 2>&1> /dev/null || brew install goreleaser
	@command -v pre-commit 2>&1> /dev/null || brew install pre-commit && pre-commit install
	@command -v go 2>&1> /dev/null || brew install go

# ====================================================================================
# Brew
# ------------------------------------------------------------------------------------

uninstall:
	@rm -rf /opt/homebrew/etc/gitconfig
	@brew uninstall $(name) --force || true
	@brew untap $(homebrew-tap) --force || true

install: uninstall
	@brew tap $(homebrew-tap) $(homebrew-tap-repository) --force-auto-update --force
	@brew update
	@brew install $(name)

overwrite-private-homebrew-download-strategy:
	@rm -rf ./.upstreams
	@sed -i -e "s/using: GitDownloadStrategy/using: GitDownloadStrategy, tag: \"$(tag)\"/g" ./dist/homebrew/Formula/$(name).rb
	@mkdir -p .upstreams
	@git clone $(homebrew-tap-repository) ./.upstreams/homebrew-taps
	@rm -f ./.upstreams/homebrew-taps/Formula/$(name).rb
	@cp -f ./dist/homebrew/Formula/$(name).rb ./.upstreams/homebrew-taps/Formula/$(name).rb
	@cd ./.upstreams/homebrew-taps && git add ./Formula/$(name).rb && git commit -m "[Chore] - Overwrote URL + Tag" && git push -u origin main
	@cd "$(git rev-parse --show-toplevel)"
	@rm -rf ./.upstreams

# ====================================================================================
# Releases
# ------------------------------------------------------------------------------------

test-release:
	@printf "$(green-bold)%s$(reset)\n" "Testing Release: $(yellow-bold)$(package)$(reset) - $(white-bold)$(version)$(reset)"
	@goreleaser release --snapshot --clean

git-check-tree:
	@if ! git diff --quiet --exit-code; then \
    	git status ; \
    	echo "" ; \
		echo "$(red-bold)Dirty Working Tree$(reset) - Commit Changes and Try Again"; \
		echo "" ; \
		exit 1; \
	else \
	    echo "$(green-bold)Clean Working Tree$(reset)"; \
	fi

bump: test git-check-tree
	@printf "$(green-bold)%s$(reset)\n" "Bumping Version: \"$(yellow-bold)$(package)$(reset)\" - $(white-bold)$(version)$(reset)"
	@echo "$($(type)-upgrade)" > VERSION

commit: bump
	@echo "$(blue-bold)Tag-Release$(reset) ($(type-title)): $(yellow-bold)$(package)$(reset) - $(white-bold)$(version)$(reset)"
	@git add VERSION
	@git commit --message "Chore ($(type-title)) - Tag Release - $(version)"
	@git push --set-upstream origin main
	@git tag "v$(version)"
	@git push origin "v$(version)"

release: commit
	@echo "$(blue-bold)Deployment$(reset) ($(type-title)): \"$(yellow-bold)$(package)$(reset)\" - $(white-bold)$(version)$(reset)"
	@goreleaser release --clean
	@echo "$(green-bold)Successful$(reset): $(version)"

# (Patch) Release Targets

bump-patch: test git-check-tree
	@echo "$(blue-bold)Bumping Version$(reset): \"$(yellow-bold)$(package)$(reset)\" - $(white-bold)$(version)$(reset)"
	@echo "$(patch-upgrade)" > VERSION

commit-patch: bump-patch
	@echo "$(blue-bold)Tag-Release (Patch)$(reset): \"$(yellow-bold)$(package)$(reset)\" - $(white-bold)$(version)$(reset)"
	@git add VERSION
	@git commit --message "Chore (Patch) - Tag Release - $(version)"
	@git push --set-upstream origin main
	@git tag "v$(version)"
	@git push origin "v$(version)"
	@echo "$(green-bold)Published Tag$(reset): $(version)"

release-patch: commit-patch
	@echo "$(blue-bold)Deployment (Patch)$(reset): \"$(yellow-bold)$(package)$(reset)\" - $(white-bold)$(version)$(reset)"
	@goreleaser release --clean
	@echo "$(green-bold)Successful$(reset): $(version)"

patch-release: pre-requisites release-patch escape-hatch install

# (Minor) Release Targets

bump-minor: test
	@if ! git diff --quiet --exit-code; then \
		echo "$(red-bold)Dirty Working Tree$(reset) - Commit Changes and Try Again"; \
		exit 1; \
	else \
		echo "$(minor-upgrade)" > VERSION; \
	fi

commit-minor: bump-minor
	@echo "$(blue-bold)Tag-Release (Minor)$(reset): \"$(yellow-bold)$(package)$(reset)\" - $(white-bold)$(version)$(reset)"
	@git add VERSION
	@git commit --message "Chore (Minor) - Tag Release - $(version)"
	@git push --set-upstream origin main
	@git tag "v$(version)"
	@git push origin "v$(version)"
	@echo "$(green-bold)Published Tag$(reset): $(version)"

release-minor: commit-minor
	@echo "$(blue-bold)Deployment (Minor)$(reset): \"$(yellow-bold)$(package)$(reset)\" - $(white-bold)$(version)$(reset)"
	@goreleaser release --clean
	@echo "$(green-bold)Successful$(reset): $(version)"

minor-release: pre-requisites release-minor escape-hatch install

# (Major) Release Targets

bump-major: test
	@if ! git diff --quiet --exit-code; then \
		echo "$(red-bold)Dirty Working Tree$(reset) - Commit Changes and Try Again"; \
		exit 1; \
	else \
		echo "$(major-upgrade)" > VERSION; \
	fi

commit-major: bump-major
	@echo "$(blue-bold)Tag-Release (Major)$(reset): \"$(yellow-bold)$(package)$(reset)\" - $(white-bold)$(version)$(reset)"
	@git add VERSION
	@git commit --message "Chore (Major) - Tag Release - $(version)"
	@git push --set-upstream origin main
	@git tag "v$(version)"
	@git push origin "v$(version)"
	@echo "$(green-bold)Published Tag$(reset): $(version)"

release-major: commit-major
	@echo "$(blue-bold)Deployment (Major)$(reset): \"$(yellow-bold)$(package)$(reset)\" - $(white-bold)$(version)$(reset)"
	@goreleaser release --clean
	@echo "$(green-bold)Successful$(reset): $(version)"

major-release: pre-requisites release-major escape-hatch install

# ====================================================================================
# CI-CD Build Targets
# ------------------------------------------------------------------------------------

build: build-darwin build-linux build-windows

# (Darwin) Build Targets

build-darwin: build-darwin-amd64 build-darwin-arm64

build-darwin-arm64: export GOOS := darwin
build-darwin-arm64: export GOARCH := arm64
build-darwin-arm64:
	$(compile)
	$(archive)

build-darwin-amd64: export GOOS := darwin
build-darwin-amd64: export GOARCH := amd64
build-darwin-amd64:
	$(compile)
	$(archive)

# (Linux) Build Targets

build-linux: build-linux-amd64 build-linux-arm64 build-linux-386

build-linux-arm64: export GOOS := linux
build-linux-arm64: export GOARCH := arm64
build-linux-arm64:
	$(compile)
	$(archive)

build-linux-amd64: export GOOS := linux
build-linux-amd64: export GOARCH := amd64
build-linux-amd64:
	$(compile)
	$(archive)

build-linux-386: export GOOS := linux
build-linux-386: export GOARCH := 386
build-linux-386:
	$(compile)
	$(archive)

# (Windows) Build Targets

build-windows: build-windows-amd64 build-windows-386

build-windows-amd64: export GOOS := windows
build-windows-amd64: export GOARCH := amd64
build-windows-amd64:
	$(compile-windows)
	$(archive-windows)

build-windows-386: export GOOS := windows
build-windows-386: export GOARCH := 386
build-windows-386:
	$(compile-windows)
	$(archive-windows)

# Additional Build Targets

clean:
	rm *.tar.gz && rm *.zip

# ====================================================================================
# Package-Specific Target(s)
# ------------------------------------------------------------------------------------

.PHONY: prepare
prepare:
	@printf "$(green-bold)%s$(reset)\n" "Tidying and Reformatting Package"
	@go mod tidy && go mod vendor
	@goimports -w -l .


.PHONY: test
test: prepare
	@printf "$(green-bold)%s$(reset)\n" "Running Test Suite"
	@go test -v --fullpath --cover ./...
