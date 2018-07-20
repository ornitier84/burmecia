#!/usr/bin/env bash
# This bootstraps Puppet on CentOS 7.x
# It has been tested on CentOS 7.0 64bit
# set error handling to exit upon error
set -e
# Check for root privileges
if [ "$EUID" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi
if ! [[ $(type /usr/{,local/}{,s}bin/puppet 2> /dev/null) && ($(puppet --version) =~ 3.8.7) ]];then
  echo "Did not find puppet binary or minimum version not met, attempting installation/ugprade ..."
else
   echo "puppet is already installed or at minimum version"
   exit 0
fi
# Check for Debian/RHEL OS Distribution
if [[ $(type /usr/{,local/}{,s}bin/rpm 2> /dev/null) ]];then
  dist=$(rpm -E '%{dist}')
elif [[ -f /etc/lsb-release ]];then
  . /etc/lsb-release
  dist=$DISTRIB_CODENAME
else
  dist=""
fi
echo "Detected OS Distribution of: ${dist}"
if [[ "$dist" =~ .*el[67].* ]]; then
    dist_num=$(echo $dist | egrep  -o '[[:digit:]]')
    rpm -ivh --replacepkgs http://yum.puppetlabs.com/puppetlabs-release-el-${dist_num}.noarch.rpm
    yum -yt install puppet-3.8.7 wget screen policycoreutils-python
elif [[ -f /etc/lsb-release ]]; then
  curl -kLO downloads.puppetlabs.com/facter/facter-2.4.0.tar.gz
  tar zxf facter-2.4.0.tar.gz
  cd facter-2.4.0
  ruby install.rb  # ruby install.rb --destdir=/usr/local/puppet
  curl -kLO downloads.puppetlabs.com/hiera/hiera-3.3.1.tar.gz
  tar zxf hiera-3.3.1.tar.gz
  cd hiera-3.3.1
  ruby install.rb
  cd -
  curl -kLO downloads.puppetlabs.com/puppet/puppet-3.8.7.tar.gz 
  tar zxf puppet-3.8.7.tar.gz
  cd puppet-3.8.7
  ruby install.rb
  cd - 
else
  echo "This OS is not supported"
  exit 1  
fi