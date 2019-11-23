#!/usr/bin/env bash

wget "$1" -O /tmp/extension.vsix && \
code-server --install-extension /tmp/extension.vsix && \
rm -f /tmp/extension.vsix
