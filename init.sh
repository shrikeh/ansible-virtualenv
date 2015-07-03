#!/usr/bin/env bash
# Used merely to make the steps in the script easier to read.
function _ansible_echo() {
  echo -e "\033[1m\n${1}\n\n\033[0m";
  tput sgr0;
}

function _ansible_command_exists() {
  local COMMAND=${1};
  command -v "${COMMAND}" >/dev/null 2>&1  || return 1;
}

function _ansible_update_pip() {
  local PIP_QUIET='--quiet';
  if [ "${1}" = true ]; then
    PIP_QUIET='';
  fi
  # Make sure we have virtualenv
  _ansible_echo 'Updating pip';
  pip install --upgrade ${PIP_QUIET} pip;
}

# Make sure we have the latest version of Virtualenv
function _ansible_get_virtualenv() {
  if ! _ansible_command_exists 'virtualenv'; then
    _ansible_echo 'Installing virtualenv';
    pip install --quiet --upgrade virtualenv virtualenvwrapper;
  fi
}

function _ansible_init_virtualenv() {
  local ANSIBLE_VENV_DIR=${1:-'venv'};

  _ansible_echo "Creating virtualenv ${ANSIBLE_VENV_DIR}";
  virtualenv "${ANSIBLE_VENV_DIR}";
  source "${ANSIBLE_VENV_DIR}/bin/activate";
}

function _init_dependencies() {
  _ansible_echo "Installing deps "
}

function _ansible_fetch_repo() {
  local ANSIBLE_CHECKOUT_PATH="${1}";
  local ANSIBLE_REPO_URI=${2:-'https://github.com/ansible/ansible.git'};
  local ANSIBLE_VERSION=${3:-'devel'};

  if [ ! -d "${ANSIBLE_CHECKOUT_PATH}" ]; then
    _ansible_echo "Cloning ansible from repo ${ANSIBLE_REPO_URI} to ${ANSIBLE_CHECKOUT_PATH}";
    git clone --quiet --recursive "${ANSIBLE_REPO_URI}" "${ANSIBLE_CHECKOUT_PATH}";
  fi
  _ansible_echo "Checking out version ${ANSIBLE_VERSION}";
  ( cd ${ANSIBLE_CHECKOUT_PATH}; \
    git checkout "${ANSIBLE_VERSION}"; \
    git pull --recurse-submodules; \
  );
}

function _ansible_hack() {
  local ANSIBLE_DIR=${1};
  source "${ANSIBLE_DIR}/hacking/env-setup";
}

function ansible_init_virtualenv() {
  echo ${1};
  echo ${#};
  local ANSIBLE_DIR='./ansible';

  _ansible_update_pip;
  _ansible_get_virtualenv;
  _ansible_fetch_repo "${ANSIBLE_DIR}";
  _ansible_init_virtualenv;
  _ansible_hack "${ANSIBLE_DIR}";
}

ansible_init_virtualenv "${@}";
