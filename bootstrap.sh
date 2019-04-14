#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

rsync --exclude ".git/" \
      --exclude ".DS_Store" \
      --exclude "bootstrap.sh" \
      --exclude "README.md" \
      --exclude "fonts" \
      -avh --no-perms . ~;

source ~/.bashrc 2>/dev/null
