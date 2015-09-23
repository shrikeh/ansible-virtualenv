# ansible-virtualenv
Set up the latest version of Ansible to run from a virtualenv on your local system.


## Basic usage
```bash
mkdir -p ./ansible-test
cd ./ansible-test
source <(curl -L --silent 'https://raw.githubusercontent.com/shrikeh/ansible-virtualenv/stable/init.sh')
```
This will:
- Update pip
- Use pip to install virtualenv if your system doesn't already have it
- Activate the virtualenv
- Install Ansible dependencies into the virtualenv
- Checkout the devel branch of ansible

Tested with bash and zsh. Pull requests welcome.

## Workaround for Mac users on bash < 4

Apple have an ancient version of bash as default on Macbooks (3.5, IIRC). Ideally, if you have homebrew (and you should), then I would recommend installing the superior version of bash from there.

If this isn't an option, then download the file and source it directly.

## Advanced usage and options

The bash script takes options, as in the example below:
```bash
export ANSIBLE_TARGET_DIR=/path/to/ansible;
export ANSIBLE_VENV_DIR=/path/to/venv;
source <(curl -L --silent 'https://raw.githubusercontent.com/shrikeh/ansible-virtualenv/stable/init.sh') \
  -dir "${ANSIBLE_TARGET_DIR}" \
  --venv "${ANSIBLE_VENV_DIR}" \
;

```
See below for a full list of supported options.

## Flags

`-d|--dir` Specify the directory that ansible will install into. Defaults to `./ansible` in the current directory.

`--venv` Specify the directory to install the virtualenv in.

`-r|--repo` Specify the remote URL to use for ansible. Useful only if you are forking ansible.

`-b|--branch` Specify the branch or tag you wish to check out. Defaults to 'devel'

`-q|--quiet` Quiet mode. Suppress some verbosity.

`--use-pip-version` Use the pip version of Ansible rather than the git repository
