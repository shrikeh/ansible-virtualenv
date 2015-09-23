#!/usr/bin/env bash
# Used merely to make the steps in the script easier to read.
_ansible_echo() {
  echo -e "\033[1m\n${1}\n\033[0m";
  \tput sgr0;
  return 0;
}

function _ansible_realpath() {
  local PATH_TO_NORMALIZE="${1}";
  echo "$(python -c 'import os,sys; print os.path.realpath(sys.argv[1])' ${PATH_TO_NORMALIZE})";
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

_ansible_pip_install_packages() {
  local PIP_BINARY="${1}";
  local PIP_PACKAGES="${2}";
  local PIP_VERBOSE="${3}";
  local PIP_USE_SUDO="${4}";

  local PIP_QUIET='--quiet';
  local PIP_UPGRADE='--upgrade';

  if [ "${PIP_VERBOSE}" = true ]; then
    PIP_QUIET='';
  fi
  if [ "${PIP_USE_SUDO}" = true ]; then
    PIP_BINARY="sudo ${PIP_BINARY}";
  fi

  local PIP_STRING="${PIP_BINARY} install ${PIP_UPGRADE} ${PIP_QUIET} ${PIP_PACKAGES[*]}";

  _ansible_echo "Running ${PIP_STRING}";

  eval "${PIP_STRING}" || return 1;
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
  python -m virtualenv "${ANSIBLE_VENV_DIR}" || return 1;
  . "${ANSIBLE_VENV_DIR}/bin/activate";
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

_ansible_hack() {
  local ANSIBLE_DIR=${1};
  source "${ANSIBLE_DIR}/hacking/env-setup";
}

ansible_init_virtualenv() {
  local ANSIBLE_DIR='./.ansible';
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

  local -a ANSIBLE_PIP_PACKAGES;
  ANSIBLE_PIP_PACKAGES=('paramiko' 'PyYAML' 'Jinja2' 'six');

  _ansible_echo 'Beginning installation of ansible in a virtualenv...';

  if [ -z "${PYTHON_PATH}" ]; then
    _ansible_echo 'Environment variable PYTHON_PATH is empty or not set. This can cause problems';
  fi

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
        ANSIBLE_PIP_PACKAGES+=('dopy');
      ;;
      --rax)
        ANSIBLE_PIP_PACKAGES+=('pyrax');
      ;;
      --uri-support)
      # Support for uri module, which requires httplib2
        ANSIBLE_PIP_PACKAGES+=('httplib2');
      ;;
      --netaddr-support)
      # Support for netaddr module, used for ipaddr filter
        ANSIBLE_PIP_PACKAGES+=('netaddr');
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
        ANSIBLE_PIP_PACKAGES+=('ansible');
      ;;
      --yolo)
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

  local ANSIBLE_VENV_DIR_REALPATH="$(_ansible_realpath ${ANSIBLE_VENV_DIR})";

  if [ "${ANSIBLE_DEBUG}" = true ]; then
    ANSIBLE_VERBOSE=true;
    if _ansible_command_exists 'deactivate'; then
      _ansible_echo 'Debug: Deactivating existing virtualenv';
      deactivate;
    fi
    _ansible_echo "Debug: Deleting existing directories ${ANSIBLE_DIR} and ${ANSIBLE_VENV_DIR_REALPATH}";
    rm -rf "${ANSIBLE_DIR}" "${ANSIBLE_VENV_DIR_REALPATH}";
  fi

  if [[ -z "${VIRTUAL_ENV}" ]]; then
    if ! _ansible_check_pip "${ANSIBLE_PIP}" "${ANSIBLE_BREW_UP}"; then
      _ansible_echo 'Failed to find pip, exiting';
      return 1;
    fi

    if ! _ansible_pip_install_packages "${ANSIBLE_PIP}" 'pip' "${ANSIBLE_VERBOSE}" "${ANSIBLE_PIP_SUDO}"; then
      _ansible_echo 'Failed to update pip';
      return 1;
    fi

    if ! _ansible_pip_install_packages "${ANSIBLE_PIP}" 'virtualenv' "${ANSIBLE_VERBOSE}" "${ANSIBLE_PIP_SUDO}"; then
      _ansible_echo 'Failed to install virtualenv';
      return 1;
    fi;

    if ! _ansible_init_virtualenv "${ANSIBLE_VENV_DIR_REALPATH}"; then
      _ansible_echo "Failed to initialise virtualenv ${ANSIBLE_VENV_DIR_REALPATH}";
      return 1;
    fi
  else
    local ANSIBLE_EXISTING_VIRTUALENV_REALPATH="$(_ansible_realpath ${VIRTUAL_ENV})";

    _ansible_echo "Virtualenv ${ANSIBLE_EXISTING_VIRTUALENV_REALPATH} detected, making assumption to use this";
  fi

  _ansible_pip_install_packages "${ANSIBLE_PIP}" "$ANSIBLE_PIP_PACKAGES" "${ANSIBLE_VERBOSE}";

  if [ "${ANSIBLE_USE_PIP_VERSION}" = false ]; then
    _ansible_fetch_repo "${ANSIBLE_VERBOSE}" "${ANSIBLE_DIR}" "${ANSIBLE_REPO_URI}" "${ANSIBLE_BRANCH}";
    _ansible_hack "${ANSIBLE_DIR}";
  fi

  _ansible_echo 'Ansible has been installed! Running ansible --version:';
  ansible --version;
  return 0;
}

ansible_init_virtualenv "${@}";
