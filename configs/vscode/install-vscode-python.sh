#!/usr/bin/env bash

version='2021.8.1159798656'

if [ ! -z "$1" ]; then
    version="$1"
fi

vsix_uri="https://github.com/microsoft/vscode-python/releases/download/${version}/ms-python-release.vsix"

wget "$vsix_uri" -O /tmp/ms-python-release.vsix && \
code-server --install-extension /tmp/ms-python-release.vsix && \
rm -f /tmp/ms-python-release.vsix
