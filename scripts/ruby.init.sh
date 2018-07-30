#!/usr/bin/env bash
# This bootstraps ruby on CentOS/Ubuntu
# It has been tested on CentOS 7.0 64bit and Ubuntu 16.04
# set error handling to exit upon error
set -e
# Initialize step counter variable
COUNT=0
# Define logger function for feedback output
logger(){
echo -e """
# STEP ${COUNT}
##### ${1} #####
#
"""
COUNT=$(( $COUNT + 1 ))
}
# Check for root privileges
if [ "$EUID" -ne "0" ]; then
  logger "This script must be run as root." >&2
  exit 1
fi
# Check for rbenv executable
executable=rbenv
if ! [[ $(type /usr/{,local/}{,s}bin/${executable} 2> /dev/null) ]];then
  logger "Did not find ${executable} binary or minimum version not met, attempting installation/ugprade ..."
else
   logger "${executable} is already installed or at minimum version"
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
logger "Detected OS Distribution of: ${dist}"
# Install required packages
if [[ "$dist" =~ .*el[67].* ]]; then
	logger "Installing required packages for $dist"
	yum install -y git-core zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison curl sqlite-devel
elif [[ -f /etc/lsb-release ]]; then
	logger "Installing required packages for $dist"
	apt-get install -y git-core zlib1g-dev gcc patch readline-common libyaml-dev libffi-dev libcurl4-openssl-dev make bzip2 autoconf automake libtool bison curl libsqlite3-dev libssl-dev
else
  logger "This OS is not supported"
  exit 1  
fi
# Install rbenv & ruby
if ! test -d /usr/local/rbenv;then 
	logger "Installing rbenv"
	git clone https://github.com/rbenv/rbenv.git /usr/local/rbenv
fi
if ! test -d /usr/local/rbenv/plugins;then 
	logger "Installing rbenv plugins"		
	mkdir /usr/local/rbenv/plugins
	git clone https://github.com/rbenv/ruby-build.git /usr/local/rbenv/plugins
fi
# Populate appropriate etc skeleton(s)
if ! test -f /etc/skel/.bash_profile;then touch /etc/skel/.bash_profile;fi
if ! egrep -wq 'begin rbenv configuration' /etc/skel/.bash_profile;then
logger "Adding rbenv configuration to /etc/skel/.bash_profile"
echo -e '''
#### begin rbenv configuration ####
## Remove these lines if you wish to use your own
## clone of rbenv (with your own rubies)
export RBENV_ROOT=/usr/local/rbenv
export PATH="$RBENV_ROOT/bin:$PATH"
eval "$(rbenv init -)"
# Allow local Gem management
export GEM_HOME="$HOME/.gem"
export GEM_PATH="$HOME/.gem"
export PATH="$HOME/.gem/bin:$PATH"
#### end rbenv configuration ####''' >> /etc/skel/.bash_profile
fi
# Populate .bash_profile skeleton
if ! egrep -wq 'begin rbenv configuration' $HOME/.bash_profile;then
	logger "Adding rbenv configuration to $HOME/.bash_profile"
echo -e '''
#### begin rbenv configuration ####
## Remove these lines if you wish to use your own
## clone of rbenv (with your own rubies)
export RBENV_ROOT=/usr/local/rbenv
export PATH="$RBENV_ROOT/bin:$PATH"
eval "$(rbenv init -)"
#### end rbenv configuration ####''' >> $HOME/.bash_profile
fi
# Install ruby build
logger "Installing ruby-build"
if ! [[ $(type /usr/{,local/}{,s}bin/ruby-build 2> /dev/null) ]];then
	if ! test -d /tmp/ruby-build;then rm -rf /tmp/ruby-build;fi
	git clone https://github.com/rbenv/ruby-build.git /tmp/ruby-build
	cd /tmp/ruby-build
	./install.sh
else
	logger "ruby-build already installed"
fi

logger "Install Ruby with OpenSSL option"
if test -d /usr/lib/ssl/;then 
	openssl_dir=/usr/lib/ssl/
else 
	openssl_dir=/usr/local
fi

if ! test -d "/usr/local/rbenv/versions/1.9.2-p290";then
	ruby-build 1.9.2-p290 /usr/local/rbenv/versions/1.9.2-p290 --with-openssl-dir=${openssl_dir}
fi

logger "Preping ruby 1.9.2-p290"

source ~/.bash_profile

# if [[ ! $($(rbenv which ruby) -v) =~ .*1.9.2.*p290.* ]];then
#  rbenv install 1.9.2-p290
# else
# 	logger "ruby 1.9.2-p290 already installed"
# fi

rbenv rehash
rbenv global 1.9.2-p290

if ! egrep -q '^#.*rbenv.*setup' /etc/profile.d/rbenv.sh;then
	echo '# rbenv setup' > /etc/profile.d/rbenv.sh
	echo 'export RBENV_ROOT=/usr/local/rbenv' >> /etc/profile.d/rbenv.sh
	echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> /etc/profile.d/rbenv.sh
	echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
	chmod +x /etc/profile.d/rbenv.sh
	source /etc/profile.d/rbenv.sh
fi

if ! eval $(gem list rbenv-rehash -i);then 
	gem install rbenv-rehash --no-ri --no-rdoc
else
	logger "gem rbenv-rehash already installed"
fi
