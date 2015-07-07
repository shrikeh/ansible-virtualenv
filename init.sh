#!/usr/bin/env bash
# Used merely to make the steps in the script easier to read.
_ansible_echo() {
  echo -e "\033[1m\n${1}\n\033[0m";
  tput sgr0;
  return 0;
}

_ansible_command_exists() {
  local COMMAND=${1};
  command -v "${COMMAND}" >/dev/null 2>&1  || return 1;
}

_ansible_check_pip() {
  local ANSIBLE_PIP="${1}";
  local ANSIBLE_BREW_UP="${2}";

  if _ansible_command_exists "${ANSIBLE_PIP}"; then
    return 0;
  else
    _ansible_echo 'Pip is required and it was not found';
    if [ "$ANSIBLE_BREW_UP" = true ]; then
      _ansible_echo 'You specified --brew so I will attempt to install Python via homebrew';
      if ! _ansible_command_exists 'brew'; then
        _ansible_echo 'Brew not found :( Sorry, I can do nothing for you';
        return 1;
      fi
      brew install --universal python;
      return 0;
    fi
  fi
  return 1;
}

_ansible_update_pip() {
  local PIP_BINARY="${1}";
  local USE_SUDO="${2}";
  local PIP_QUIET='--quiet';
  if [ "${3}" = true ]; then
    PIP_QUIET='';
  fi
  if [ "${USE_SUDO}" = true ]; then
    PIP_BINARY="sudo ${PIP_BINARY}";
  fi
  # Make sure we have virtualenv
  _ansible_echo 'Updating pip';
  eval "${PIP_BINARY} install --upgrade ${PIP_QUIET} pip" || return 1;
}

# Make sure we have the latest version of Virtualenv
_ansible_get_virtualenv() {
  local PIP_BINARY="${1}";
  local USE_SUDO="${2}";

  local PIP_QUIET='--quiet';
  if [ "${3}" = true ]; then
    PIP_QUIET='';
  fi

  if [ "${USE_SUDO}" = true ]; then
    PIP_BINARY="sudo ${PIP_BINARY}";
  fi
  if ! _ansible_command_exists 'virtualenv'; then
    _ansible_echo 'Installing virtualenv';
    eval "${PIP_BINARY} install --user --upgrade ${PIP_QUIET} virtualenv" || return 1;
  fi
  return 0;
}

_ansible_init_virtualenv() {
  local ANSIBLE_VENV_DIR="${1}";
  if [ -z "${ANSIBLE_VENV_DIR}" ]; then
    _ansible_echo 'Variable ${ANSIBLE_VENV_DIR} was empty';
    return 1;
  fi
  _ansible_echo "Creating virtualenv ${ANSIBLE_VENV_DIR}";
  mkdir -p "${ANSIBLE_VENV_DIR}";
  if [ ! -w "${ANSIBLE_VENV_DIR}" ]; then
      _ansible_echo "Directory ${ANSIBLE_VENV_DIR} does not exist or is not writable";
      return 1;
  fi
  virtualenv "${ANSIBLE_VENV_DIR}" || return 1;
  . "${ANSIBLE_VENV_DIR}/bin/activate";
  return 0;
}

_ansible_init_dependencies() {
  local ANSIBLE_DIR="${1}";
  local PIP_QUIET='--quiet';
  local REQUIREMENTS_FILE='./lib/ansible.egg-info/requires.txt';

  if [ "${2}" = true ]; then
    PIP_QUIET='';
  fi

  #local PIP_REQUIREMENTS="${ANSIBLE_DIR}/${REQUIREMENTS_FILE}";
  #_ansible_echo "Attempting to install dependencies from ${PIP_REQUIREMENTS}";
  #if [ ! -e "${PIP_REQUIREMENTS}" ]; then
  #  _ansible_echo "File ${PIP_REQUIREMENTS} was not found or not readable";
  #  return 1;
  #else
    _ansible_echo 'Installing dependencies';
    pip install $PIP_QUIET --upgrade paramiko PyYAML Jinja2 httplib2 six || return 1;
  #fi
  return 0;
}

_ansible_fetch_repo() {
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
  return 0;
}

_ansible_do() {
  local PIP_QUIET='--quiet';
  if [ "${1}" = true ]; then
    PIP_QUIET='';
  fi
  _ansible_echo 'Installing dopy';
  pip install $PIP_QUIET --upgrade dopy || return 1;
  return 0;
}

_ansible_rax() {
  local PIP_QUIET='--quiet';
  if [ "${1}" = true ]; then
    PIP_QUIET='';
  fi
  _ansible_echo 'Installing pyrax';
  pip install $PIP_QUIET --upgrade pyrax || return 1;
  return 0;
}

_ansible_hack() {
  local ANSIBLE_DIR=${1};

  source "${ANSIBLE_DIR}/hacking/env-setup";
}

ansible_init_virtualenv() {
  local ANSIBLE_DIR='./ansible';
  local ANSIBLE_REPO_URI='https://github.com/ansible/ansible.git';
  local ANSIBLE_BRANCH='devel';
  local ANSIBLE_VENV_DIR='venv';
  local ANSIBLE_VERBOSE=true;
  local ANSIBLE_PIP='pip';
  local ANISBLE_PIP_SUDO=false;
  local ANSIBLE_USE_PIP_VERSION=false;
  local ANSIBLE_UPDATE_PIP=false;
  local ANSIBLE_DEBUG=false;
  local ANSIBLE_BREW_UP=false;
  local ANSIBLE_DO_SUPPORT=false;
  local ANSIBLE_RAX_SUPPORT=false;
  local ANSIBLE_URI_SUPPORT=false;

  _ansible_echo 'Beginning installation of ansible in a virtualenv...';

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
      --do)
        ANSIBLE_DO_SUPPORT=true;
      ;;
      --rax)
        ANSIBLE_RAX_SUPPORT=true;
      ;;
      --uri)
      # Support for uri module, which requires httplib2
        ANSIBLE_URI_SUPPORT=true;
      ;;
      --brew)
        ANSIBLE_BREW_UP=true;
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
      --sudo)
        ANSIBLE_PIP_SUDO=true;
        _ansible_echo "Pip will run with sudo. This is a fantastically bad idea, IMHO. But, OK...";
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
        if [ -z "${2}" ]; then
          _ansible_echo 'You specified --pip but it was empty';
          return 1;
        fi
        ANSIBLE_PIP="${2}";
      shift
      ;;
      *)
      # unknown option
      ;;
  esac
    shift
  done


  if [ "${ANSIBLE_DEBUG}" = true ]; then
    ANSIBLE_VERBOSE=true;
    if _ansible_command_exists 'deactivate'; then
      _ansible_echo 'Debug: Deactivating existing virtualenv';
      deactivate;
    fi
    _ansible_echo "Debug: Deleting existing directories ${ANSIBLE_DIR} and ${ANSIBLE_VENV_DIR}";
    rm -rf "${ANSIBLE_DIR}" "${ANSIBLE_VENV_DIR}";
  fi

  if ! _ansible_check_pip "${ANSIBLE_PIP}" "${ANSIBLE_BREW_UP}"; then
    _ansible_echo 'Failed to find pip, exiting';
    return 1;
  fi

  if [[ -z "${VIRTUAL_ENV}" ]]; then
    if ! _ansible_update_pip "${ANSIBLE_PIP}" "${ANSIBLE_PIP_SUDO}" "${ANSIBLE_VERBOSE}"; then
      _ansible_echo 'Failed to update pip';
      return 1;
    fi

    if ! _ansible_get_virtualenv "${ANSIBLE_PIP}" "${ANSIBLE_PIP_SUDO}" "${ANSIBLE_VERBOSE}"; then
      _ansible_echo 'Failed to install virtualenv';
      return 1;
    fi;

    if ! _ansible_init_virtualenv "${ANSIBLE_VENV_DIR}"; then
      _ansible_echo "Failed to initialise virtualenv ${ANSIBLE_VENV_DIR}";
      return 1;
    fi
  else
    _ansible_echo "Virtualenv ${VIRTUAL_ENV} detected, making assumption to use this";
  fi


  if [ "${ANSIBLE_USE_PIP_VERSION}" = true ]; then
    _ansible_echo 'Using ansible version from pip';
    pip install --upgrade ansible;
  else
    _ansible_fetch_repo "${ANSIBLE_VERBOSE}" "${ANSIBLE_DIR}" "${ANSIBLE_REPO_URI}" "${ANSIBLE_BRANCH}";
    _ansible_hack "${ANSIBLE_DIR}";
    _ansible_init_dependencies "${ANSIBLE_DIR}" "${ANSIBLE_VERBOSE}";
  fi

  if [ "${ANSIBLE_DO_SUPPORT}" = true ]; then
    _ansible_do;
  fi

  if [ "${ANSIBLE_RAX_SUPPORT}" = true ]; then
    _ansible_rax;
  fi

  _ansible_echo 'Ansible has been installed! Running ansible --version:';
  ansible --version;
  return 0;
}

ansible_init_virtualenv "${@}";
