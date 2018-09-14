#!/bin/bash
# Source: https://github.com/geerlingguy/JJG-Ansible-Windows/blob/master/windows.sh

# Windows shell provisioner for Ansible playbooks, based on KSid's
# windows-vagrant-ansible: https://github.com/KSid/windows-vagrant-ansible
#
# @todo - Allow proxy configuration to be passed in via Vagrantfile config.
#
# @see README.md
# @author Jeff Geerling, 2014
# @version 1.0
#

#
# Bash shell settings: exit on failing commands, unbound variables
#
set -o errexit
set -o nounset
set -o pipefail

ANSIBLE_KEEP_REMOTE_FILES=0
ANSIBLE_ROLES_PATH=/vagrant/provisioners/ansible/roles:/vagrant/provisioners/ansible/roles.global
ANSIBLE_LIBRARY=/vagrant/provisioners/ansible/library/modules
LIMIT_HOSTNAME="-l all"
CONNECTION=local
inventory=/vagrant/scripts/inventory.py
playbook=/vagrant/provisioners/ansible/site.yml
PREFIX=""
GROUP=""

while (( "$#" )); do
    if [[ "$1" =~ .*--playbook.* ]]; then playbook="${2}";fi
    if [[ "$1" =~ .*--roles-path.* ]]; then ANSIBLE_ROLES_PATH="${2}";fi
    if [[ "$1" =~ .*--modules-path.* ]]; then ANSIBLE_LIBRARY="${2}";fi
    if [[ "$1" =~ .*--inventory.* ]]; then inventory="${2}";fi
    if [[ "$1" =~ .*--connection.* ]]; then CONNECTION="${2}";fi
    if [[ "$1" =~ .*--provisioners_root_dir.* ]]; then PROVISIONERS_ROOT_DIR="${2}";fi
    if [[ "$1" =~ .*--limit.* ]]; then LIMIT_HOSTNAME="-l ${2}";fi
    if [[ "$1" =~ .*--groups.* ]]; then GROUP="${2}";fi
    if [[ "$1" =~ .*--debug.* ]]; then ANSIBLE_KEEP_REMOTE_FILES=1;fi
    if [[ "$1" =~ .*--dry.* ]]; then PREFIX=echo;fi
    shift
done

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
  info "Running Ansible playbook ${playbook} locally on host ${HOSTNAME}."
  exit_on_vyos
  check_if_playbook_exists
  check_if_inventory_exists
  ensure_ansible_installed
  run_playbook "${@}"
}

exit_on_vyos() {
  # If we're on a VyOS box, this script shouldn't be executed
  if user_exists vyos; then
    debug "On VyOS, not running Ansible here"
    exit 0
  fi
}

check_if_playbook_exists() {
  if [ ! -f ${playbook} ]; then
    die "Cannot find Ansible playbook ${playbook}."
  fi
}

check_if_inventory_exists() {
  if [ ! -f ${inventory} ]; then
    die "Cannot find inventory file ${inventory}."
  fi
}

ensure_binary_installed() {
  binary=$1
  if ! is_binary_installed "${binary}"; then
    distro=$(get_linux_distribution)
    "install_binary_${distro}" ${binary} || die """
    Distribution ${distro} is not supported or 
    we encountered an error in execution!"""
  fi

  info "${binary} version"
  $binary --version
}

ensure_ansible_installed() {
  if ! is_ansible_installed; then
    distro=$(get_linux_distribution)
    "install_ansible_${distro}" || die """
    Distribution ${distro} is not supported or 
    we encountered an error in execution!"""
  fi
  
  which ansible > /dev/null 2>&1 || die """
    Ansible failed to install!"""

  info "Ansible version"
  ansible --version
}

is_binary_installed() {
  which "${1}" > /dev/null 2>&1
}

is_ansible_installed() {
  which ansible-playbook > /dev/null 2>&1
}

run_playbook() {
  info "Running the playbook"

  # Get absolute path to playbook command
  playbook_cmd=$(which ansible-playbook)

  export ANSIBLE_KEEP_REMOTE_FILES=$ANSIBLE_KEEP_REMOTE_FILES
  export ANSIBLE_ROLES_PATH=$ANSIBLE_ROLES_PATH
  export ANSIBLE_LIBRARY=$ANSIBLE_LIBRARY
  ${PREFIX} ${playbook_cmd} "${playbook}" \
    --inventory-file="${inventory}" \
    "${LIMIT_HOSTNAME}" \
    --extra-vars "is_windows=true,provisioners_root_dir=${PROVISIONERS_ROOT_DIR},host_key_checking=False" \
    --connection=${CONNECTION} \
    "$@"
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

# Install Ansible on a Fedora system.
# The version in the repos is fairly current, so we'll install that
install_ansible_fedora() {
  info "Fedora: installing Ansible from distribution repositories"
  dnf -y install ansible
}

# Install Ansible on a CentOS system from EPEL
install_ansible_oracle() {
  info "Oracle: installing EPEL "
  if [[ "$(awk '{print $NF}' /etc/oracle-release)" =~ 7.* ]];then
    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum update 
    yum install -y ansible
  elif [[ "$(awk '{print $NF}' /etc/oracle-release)" =~ 6.* ]];then
    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
    yum update 
    yum install -y ansible
  fi
}

# Install Ansible on a CentOS system from EPEL
install_ansible_centos() {
  info "CentOS: installing Ansible from the EPEL repository"
  yum -y install epel-release
  if ! yum -y install ansible;then
    curl -Oks https://bootstrap.pypa.io/get-pip.py
    sudo python get-pip.py --trusted-host pypi.python.org
    pip install ansible --trusted-host pypi.python.org
  fi  
}

# Install a specified binary on a recent Ubuntu distribution
install_binary_ubuntu() {
  sudo apt-get update
  sudo apt-get install -y $1
}

# Install Ansible on a recent Ubuntu distribution, from the PPA
install_ansible_ubuntu() {
  info "Ubuntu: installing Ansible via pip"
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
  
  if ! (sudo apt-add-repository -y ppa:ansible/ansible && apt-get update && apt-get -y install ansible 2>/dev/null);then 
    echo "Failed to install ansible via apt-get, trying via pip ..."
    if ! sudo pip install ansible cryptography --trusted-host pypi.python.org --trusted-host pypi.org 2>/dev/null;then
        echo "Failed to install ansible via pip, giving up ..."
        return 1
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
