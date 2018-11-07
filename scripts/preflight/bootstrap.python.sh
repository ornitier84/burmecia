#!/bin/bash

#
# Bash shell settings: exit on failing commands, unbound variables
#
set -o errexit
set -o nounset
set -o pipefail

#
# Variables
#
# Color definitions
readonly reset='\e[0m'
readonly red='\e[0;31m'
readonly yellow='\e[0;33m'
readonly cyan='\e[0;36m'

#
# Functions
#
main() {
  info "Bootstrapping python on ${HOSTNAME}"
  exit_on_vyos
  ensure_binary_installed python
  ensure_binary_installed pip
}

exit_on_vyos() {
  # If we're on a VyOS box, this script shouldn't be executed
  if user_exists vyos; then
    debug "On VyOS, not running Ansible here"
    exit 0
  fi
}

ensure_binary_installed() {
  binary=$1
  if ! is_binary_installed "${binary}"; then
    distro=$(get_linux_distribution)
    "install_${binary}_${distro}" ${binary} || die """
    Distribution ${distro} is not supported or 
    we encountered an error in execution!"""
  fi

  info "${binary} version"
  $binary --version
}

is_binary_installed() {
  which "${1}" > /dev/null 2>&1
}

# Print the Linux distribution
get_linux_distribution() {

  if user_exists vyos; then

    echo "vyos"

  elif [[ ( -f '/etc/redhat-release' ) && ! ( -f '/etc/oracle-release' ) ]]; then

    # RedHat-based distributions
    cut --fields=1 --delimiter=' ' '/etc/redhat-release' \
      | tr "[:upper:]" "[:lower:]"

  elif [ -f '/etc/oracle-release' ]; then

    # Oracle-based distributions
    cut --fields=1 --delimiter=' ' '/etc/oracle-release' \
      | tr "[:upper:]" "[:lower:]"

  elif [ -f '/etc/lsb-release' ]; then

    # Debian-based distributions
    grep DISTRIB_ID '/etc/lsb-release' \
      | cut --delimiter='=' --fields=2 \
      | tr "[:upper:]" "[:lower:]"

  fi
}

# Install python on a recent Ubuntu distribution, from the PPA
install_python_ubuntu() {
  info "Ubuntu: installing python ..."
  sudo apt-get update
  sudo apt-get install -y curl software-properties-common || sudo apt-get install -y python-software-properties
  sudo apt-get -y autoremove
  # Remark: on older Ubuntu versions, it's python-software-properties
  sudo apt-get install -y --allow-unauthenticated python-setuptools python-dev libffi-dev libssl-dev git sshpass tree
}

# Install pip on a recent Ubuntu distribution, from the PPA
install_pip_ubuntu() {
  info "Ubuntu: installing pip ..."
  sudo apt-get update
  sudo apt-get install -y curl software-properties-common || sudo apt-get install -y python-software-properties
  sudo apt-get -y autoremove
  # Remark: on older Ubuntu versions, it's python-software-properties
  sudo apt-get install -y --allow-unauthenticated python-setuptools python-dev libffi-dev libssl-dev git sshpass tree
  
  if ! sudo apt-get -y install python-pip 2>/dev/null;then 
    echo "Failed to install pip via apt-get, trying easy_install ..."
    if ! sudo easy_install -q pip 2>/dev/null;then
      echo "Failed to install pip via easy_install, trying via get-pip.py ..."
      curl -Oks https://bootstrap.pypa.io/get-pip.py
      if ! sudo python get-pip.py --trusted-host pypi.python.org --trusted-host pypi.org 2>/dev/null;then
        echo "Failed to install pip via get-pip.py, giving up ..."
      fi
    fi 
  fi
}

# Checks if the specified user exists
user_exists() {
  user_name="${1}"
  getent passwd "${user_name}" > /dev/null
}

# Usage: info [ARG]...
#
# Prints all arguments on the standard output stream
info() {
  printf "${yellow}>>> %s${reset}\n" "${*}"
}

# Usage: debug [ARG]...
#
# Prints all arguments on the standard output stream
debug() {
  printf "${cyan}### %s${reset}\n" "${*}"
}

# Usage: error [ARG]...
#
# Prints all arguments on the standard error stream
error() {
  printf "${red}!!! %s${reset}\n" "${*}" 1>&2
}

# Usage: die MESSAGE
# Prints the specified error message and exits with an error status
die() {
  error "${*}"
  exit 1
}

main
