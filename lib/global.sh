#!/bin/bash

# -- common globals
LOGFILE="logs/console.log"
INSTALLFILE="/root/openstack-install.status"

# -- helper functions
function printInfo {
  printf "%-70s" "$1"
}

function printSuccess {
  echo -e "[ \e[92mdone\e[0m ]"
}

function printError {
  echo -e "[ \e[91mfail\e[0m ]"
  exit 1
}

# -- Dependencies handling
function installRepoPackages {
  printInfo "Installing required repository dependencies..."

  sudo grep "REPO_DEPS_INSTALL" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    installIfRequired yum-plugin-priorities
    installIfRequired rdo-release-icehouse something http://repos.fedorapeople.org/repos/openstack/openstack-icehouse/rdo-release-icehouse-3.noarch.rpm
    installIfRequired epel-release http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    installIfRequired openstack-utils
    installIfRequired openstack-selinux
    sudo echo "REPO_DEPS_INSTALL" >> $INSTALLFILE
  fi

  printSuccess
}

# -- install a package if it is not yet installed
# -- Inputs:
# --- $1 - Name of Package
# --- $2 - (Optional) path to Package to install
function installIfRequired {
  sudo rpm -qi $1 &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    if [ ! -z $2 ]; then
      sudo yum -y install $2 &>$LOGFILE || { printError; }
    else
      sudo yum -y install $1 &>$LOGFILE || { printError; }
    fi
  fi
}

# -- install required packages/configurations for follow-on configs
function installPrerequisites {
  printInfo "Installing required dependencies..."

  sudo grep "PREREQUISITES" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    installIfRequired cronie
    sudo echo "PREREQUISITES" >> $INSTALLFILE
  fi

  printSuccess
}
