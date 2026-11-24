# -----------------------------------------
# Makefile – DOS program (Open Watcom), the steps of the served pipeline
# -----------------------------------------
# The dos-* commands come with the dos-builder image: run these targets in the
# dev container (the WarpEngine Toolbox does), or install Open Watcom and the
# commands of dos-tools/bin yourself.

PROJECT = myprog

METADATA = metadata.json
VERSION  = $(shell sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' $(METADATA) | head -n 1)
EXE      = $(shell sed -n 's/.*"folder"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' $(METADATA) | head -n 1)

all: build

# builds the program and packs the release zip into dist/, which Play runs
build:
	dos-check
	dos-build
	TAG=v$(or $(VERSION),0.0.0) dos-pack

check:
	dos-check

test: build
	dos-test

# runs the program in a local DOSBox (not in the dev container)
run:
	dosbox -c "mount c ." -c "c:" -c "$(or $(EXE),$(shell echo $(PROJECT) | tr a-z A-Z)).EXE"

clean:
	rm -rf dist SOURCE/build .release-assets

.PHONY: all build check test run clean
