# CI builder image for DOS programs: everything the WarpEngine dos pipeline runs, so a
# program's repo carries no CI scripts of its own (only `platform: dos` and metadata.json).
#   - Open Watcom v2 in /opt/watcom (binl64, h, lib286, lib386): DOS and Win32 builds
#   - DOSBox Staging in /opt/dosbox-staging (headless end-to-end tests, NE2000), and
#     Debian's DOSBox 0.74 on the PATH (the screen tests of GMENU and BMAGIC); Staging is
#     deliberately not on the PATH, run.py would otherwise pick it
#   - Wine 32-bit (the Win32 tests), g++ (unit tests), python3 + pyftpdlib (test FTP
#     server), clang-format in /opt/clang-format, zip/unzip/jq/curl
#   - bin/dos-{check,build,test,pack}: the pipeline's steps (see README.md)
# The pinned versions are listed in /opt/dos-ci/versions.
#
# Build & push (the CI runner is linux/amd64):
#   docker build --platform linux/amd64 -f builder.Dockerfile \
#     -t git.teletypegames.org/build/dos-builder:latest .
#   docker push git.teletypegames.org/build/dos-builder:latest
FROM debian:bookworm-slim

ARG OW_RELEASE=2026-10-01-Build
ARG DOSBOX_VERSION=v0.83.0
ARG CLANG_FORMAT_VERSION=18.1.8

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl xz-utils zip unzip jq \
      python3 python3-pyftpdlib python3-venv g++ perl dosbox \
      libasound2 libgl1 libglib2.0-0 libxkbcommon0 wine wine32 \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/watcom /opt/dosbox-staging /opt/dos-ci \
 && curl -fsSL "https://github.com/open-watcom/open-watcom-v2/releases/download/$OW_RELEASE/ow-snapshot.tar.xz" \
    | tar -xJ -C /opt/watcom ./binl64 ./h ./lib286 ./lib386 \
 && curl -fsSL "https://github.com/dosbox-staging/dosbox-staging/releases/download/$DOSBOX_VERSION/dosbox-staging-linux-x86_64-$DOSBOX_VERSION.tar.xz" \
    | tar -xJ -C /opt/dosbox-staging --strip-components=1 \
 && python3 -m venv /opt/clang-format \
 && /opt/clang-format/bin/pip install --quiet --no-cache-dir "clang-format==$CLANG_FORMAT_VERSION" \
 && printf 'OW_RELEASE=%s\nDOSBOX_VERSION=%s\nCLANG_FORMAT_VERSION=%s\n' \
      "$OW_RELEASE" "$DOSBOX_VERSION" "$CLANG_FORMAT_VERSION" > /opt/dos-ci/versions

ENV WATCOM=/opt/watcom \
    CLANG_FORMAT=/opt/clang-format/bin/clang-format

COPY bin/ /usr/local/bin/
RUN chmod +x /usr/local/bin/dos-*

WORKDIR /workspace
CMD ["/bin/bash"]
