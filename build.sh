#!/bin/bash

set -e

yarn monaco-compile-check
yarn valid-layers-check

yarn gulp compile-build
yarn gulp compile-extension-media
yarn gulp compile-extensions-build
yarn gulp minify-vscode

yarn gulp "vscode-darwin-arm64-min-ci"

