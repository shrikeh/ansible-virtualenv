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
  pip install --upgrade "${PIP_QUIET}" pip;
}

# Make sure we have the latest version of Virtualenv
function _ansible_get_virtualenv() {
  local PIP_QUIET='--quiet';
  if [ "${1}" = true ]; then
    PIP_QUIET='';
  fi
  if ! _ansible_command_exists 'virtualenv'; then
    _ansible_echo 'Installing virtualenv';
    pip install "${PIP_QUIET}" --upgrade virtualenv virtualenvwrapper;
  fi
}

function _ansible_init_virtualenv() {
  local ANSIBLE_VENV_DIR="${1}";

  _ansible_echo "Creating virtualenv ${ANSIBLE_VENV_DIR}";
  virtualenv "${ANSIBLE_VENV_DIR}";
  source "${ANSIBLE_VENV_DIR}/bin/activate";
}

function _init_dependencies() {
  _ansible_echo "Installing dependencies";
}

function _ansible_fetch_repo() {
  local ANSIBLE_QUIET='--quiet';
  local ANSIBLE_CHECKOUT_PATH="${2}";
  local ANSIBLE_REPO_URI="${3}";
  local ANSIBLE_BRANCH=${4};

  if [ "${1}" = true ]; then
    ANISBLE_QUIET='';
  fi

  if [ ! -d "${ANSIBLE_CHECKOUT_PATH}" ]; then
    _ansible_echo "Cloning ansible from repo ${ANSIBLE_REPO_URI} to ${ANSIBLE_CHECKOUT_PATH}";
    git clone "${ANSIBLE_QUIET}" --recursive "${ANSIBLE_REPO_URI}" "${ANSIBLE_CHECKOUT_PATH}";
  fi
  _ansible_echo "Checking out branch ${ANSIBLE_BRANCH}";
  ( cd ${ANSIBLE_CHECKOUT_PATH}; \
    git checkout "${ANSIBLE_QUIET}" "${ANSIBLE_BRANCH}"; \
    git pull "${ANSIBLE_QUIET}" --recurse-submodules; \
  );
}

function _ansible_hack() {
  local ANSIBLE_DIR=${1};

  source "${ANSIBLE_DIR}/hacking/env-setup";
}

function ansible_init_virtualenv() {
  local ANSIBLE_DIR='./ansible';
  local ANSIBLE_REPO_URI='https://github.com/ansible/ansible.git';
  local ANSIBLE_BRANCH='devel';
  local ANSIBLE_VENV_DIR='venv';
  local ANSIBLE_VERBOSE=true;

  while [[ "${#}" > 0 ]]; do
    local key="${1}";

    case ${key} in
      -d|--dir)
        ANSIBLE_DIR="${2}";
      shift
      ;;
      -r|--repo)
        ANSIBLE_REPO_URI="${2}";
      shift
      ;;
      -b|--branch)
        ANSIBLE_BRANCH="${2}";
      shift
      ;;
      --venv)
        ANSIBLE_VENV_DIR="${2}";
      shift
      ;;
      -q|--quiet)
        ANSIBLE_VERBOSE=false;
      shift
      ;;
      --default)
        DEFAULT=YES
      shift
      ;;
      *)
              # unknown option
      ;;
  esac
    shift
  done

  if [[ -z "${VIRTUAL_ENV}" ]]; then
    _ansible_update_pip "${ANSIBLE_VERBOSE}";
    _ansible_get_virtualenv "${ANSIBLE_VERBOSE}";
    _ansible_init_virtualenv "${ANSIBLE_VENV_DIR}";
  else
    _ansible_echo "Virtualenv ${VIRTUAL_ENV} detected, assuming to use this";
  fi
  _ansible_fetch_repo "${ANSIBLE_VERBOSE}" "${ANSIBLE_DIR}" "${ANSIBLE_REPO_URI}" "${ANSIBLE_BRANCH}";
  _ansible_hack "${ANSIBLE_DIR}";
}

ansible_init_virtualenv "${@}";
