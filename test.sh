#!/usr/bin/env bash

function ansible_mac() {
  local ANISBLE_VIRTUALENV_SCRIPT_URI="https://raw.githubusercontent.com/shrikeh/ansible-virtualenv/${ANSIBLE_INSTALLER_BRANCH:-develop}/init.sh";
  local ANSIBLE_VIRTUALENV_SCRIPT_TMP_DIR="$(mktemp -d -t 'ansible_virtualenv')";
  curl -o "${ANSIBLE_VIRTUALENV_SCRIPT_TMP_DIR}/init.sh" -L "${ANISBLE_VIRTUALENV_SCRIPT_URI}";
  source "${ANSIBLE_VIRTUALENV_SCRIPT_TMP_DIR}/init.sh" ${@};
}

ansible_mac ${@};
