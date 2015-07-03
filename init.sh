#!/usr/bin/env bash
# Used merely to make the steps in the script easier to read.
function _ansible_echo() {
  echo -e "\033[1m\n${1}\n\033[0m";
  tput sgr0;
}

function _ansible_command_exists() {
  local COMMAND=${1};
  command -v "${COMMAND}" >/dev/null 2>&1  || return 1;
}

function _ansible_update_pip() {
  local PIP_BINARY="${1}";
  local PIP_QUIET='--quiet';
  if [ "${2}" = true ]; then
    PIP_QUIET='';
  fi
  # Make sure we have virtualenv
  _ansible_echo 'Updating pip';
  pip install --upgrade ${PIP_QUIET} pip;
}

# Make sure we have the latest version of Virtualenv
function _ansible_get_virtualenv() {
  local PIP_BINARY="${1}";
  local PIP_QUIET='--quiet';
  if [ "${2}" = true ]; then
    PIP_QUIET='';
  fi
  if ! _ansible_command_exists 'virtualenv'; then
    _ansible_echo 'Installing virtualenv';
    pip install ${PIP_QUIET} --upgrade virtualenv virtualenvwrapper;
  fi
}

function _ansible_init_virtualenv() {
  local ANSIBLE_VENV_DIR="${1}";

  _ansible_echo "Creating virtualenv ${ANSIBLE_VENV_DIR}";
  virtualenv "${ANSIBLE_VENV_DIR}";
  source "${ANSIBLE_VENV_DIR}/bin/activate";
}

function _ansible_init_dependencies() {
  local PIP_QUIET='--quiet';
  if [ "${1}" = true ]; then
    PIP_QUIET='';
  fi
  _ansible_echo "Installing dependencies via pip";
  pip install ${PIP_QUIET} --upgrade pip paramiko PyYAML Jinja2 httplib2 six;
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
  _ansible_echo "Checking out branch ${ANSIBLE_BRANCH} in ${ANSIBLE_CHECKOUT_PATH}";

  ( cd ${ANSIBLE_CHECKOUT_PATH}; \
    git checkout ${ANSIBLE_QUIET} "${ANSIBLE_BRANCH}"; \
    git pull ${ANSIBLE_QUIET} --recurse-submodules; \
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
  local ANSIBLE_PIP='pip';
  local ANSIBLE_USE_PIP_VERSION=false;
  local UPDATE_PIP=false;
  local ANSIBLE_DEBUG=false;

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
        _ansible_echo 'Using quiet mode, shhhh';
      ;;
      --use-pip-version)
        ANSIBLE_USE_PIP_VERSION=true;
      ;;
      --temp)
        ANSIBLE_TEMP_DIR=$(`mktemp -d 2>/dev/null || mktemp -d -t $TMP_DIR`);
      ;;
      --debug)
        ANSIBLE_DEBUG=true;
        _ansible_echo 'Debug mode on';
      ;;
      --pip)
        _ansible_echo "The --pip option currently does nothing. I'm working on it";
        ANSIBLE_PIP="${2}";
      shift
      ;;
      *)
              # unknown option
      ;;
  esac
    shift
  done

  if ! _ansible_command_exists 'source'; then
    alias 'source' '.';
  fi


  if [ "${ANSIBLE_DEBUG}" = true ]; then
    ANSIBLE_VERBOSE=true;
    if _ansible_command_exists 'deactivate'; then
      _ansible_echo 'Debug: Deactivating existing virtualenv';
      deactivate;
    fi
    _ansible_echo "Debug: Deleting existing directories ${ANSIBLE_DIR} and ${ANSIBLE_VENV_DIR}";
    rm -rf "${ANSIBLE_DIR}" "${ANSIBLE_VENV_DIR}";
  fi

  if ! _ansible_command_exists "${ANSIBLE_PIP}"; then
    _ansible_echo 'Pip is required and it was not found';
    return false;
  fi

  if [[ -z "${VIRTUAL_ENV}" ]]; then
    _ansible_update_pip "${ANSIBLE_PIP}" "${ANSIBLE_VERBOSE}";
    _ansible_get_virtualenv "${ANSIBLE_PIP}" "${ANSIBLE_VERBOSE}";
    _ansible_init_virtualenv "${ANSIBLE_VENV_DIR}";
  else
    _ansible_echo "Virtualenv ${VIRTUAL_ENV} detected, assuming to use this";
  fi

  _ansible_init_dependencies "${ANSIBLE_VERBOSE}";

  if [ "${ANSIBLE_USE_PIP_VERSION}" = true ]; then
    _ansible_echo 'Using ansible version from pip';
    pip install --upgrade ansible;
  else
    _ansible_fetch_repo "${ANSIBLE_VERBOSE}" "${ANSIBLE_DIR}" "${ANSIBLE_REPO_URI}" "${ANSIBLE_BRANCH}";
    _ansible_hack "${ANSIBLE_DIR}";
  fi

  _ansible_echo 'Ansible has been installed! Try running `ansible --version` to see if it worked';
  return true;
}

ansible_init_virtualenv "${@}";
