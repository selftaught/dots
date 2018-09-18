#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

function install_dots {
	rsync --exclude ".git/" \
          --exclude ".DS_Store" \
          --exclude "bootstrap.sh" \
          --exclude "README.md" \
          --exclude "fonts" \
          -avh --no-perms . ~;
	source ~/.zshrc;
}

install_dots
unset install_dots;
source ~/.bashrc
