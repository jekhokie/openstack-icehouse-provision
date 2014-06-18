#!/bin/bash

# -- required includes
. lib/helper.sh
. configs.sh
. control.sh
. network.sh
. compute.sh

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

# -- common network configurations and checks
function configureIptables {
  printInfo "Starting IPTables and configuring to start on boot..."

  sudo grep "IPTABLES" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo service iptables start &>$LOGFILE || { printError; }
    sudo chkconfig iptables on  &>$LOGFILE || { printError; }
    sudo echo "IPTABLES" >> $INSTALLFILE
  fi

  printSuccess
}

function configureHostsFile {
  printInfo "Configuring /etc/hosts file..."

  sudo grep "HOSTS_FILE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo grep "$CONTROLLER_IP" /etc/hosts &>$LOGFILE || echo -e "\n# controller\n$CONTROLLER_IP controller" >> /etc/hosts || { printError; }
    sudo grep "$NETWORK_IP"    /etc/hosts &>$LOGFILE || echo -e "\n# network\n$NETWORK_IP network"          >> /etc/hosts || { printError; }
    sudo grep "$COMPUTE1_IP"   /etc/hosts &>$LOGFILE || echo -e "\n# compute1\n$COMPUTE1_IP compute1"       >> /etc/hosts || { printError; }
    sudo echo "HOSTS_FILE" >> $INSTALLFILE
  fi

  printSuccess
}

# -- NTP handling
function installNtpClient {
  printInfo "Installing, configuring, and starting NTP as a Client..."

  sudo grep "NTP_CLIENT_INSTALL" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo yum -y install ntp &>$LOGFILE || { printError; }
    sudo echo "NTP_CLIENT_INSTALL" >> $INSTALLFILE
  fi

  sudo grep "NTP_CLIENT_CONFIGURE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo grep -E "^server\s$CONTROLLER_IP" /etc/ntp.conf &>$LOGFILE
    if [[ $? -ne 0 ]]; then
      sudo sed -ie 's:^server.*::g' /etc/ntp.conf &>$LOGFILE || { printError; }
      sudo echo -e "\nserver $CONTROLLER_IP" >> /etc/ntp.conf
    fi
    sudo echo "NTP_CLIENT_CONFIGURE" >> $INSTALLFILE
  fi

  sudo grep "NTP_CLIENT_START" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo service ntpd start &>$LOGFILE || { printError; }
    sudo echo "NTP_CLIENT_START" >> $INSTALLFILE
  fi

  printSuccess
}

function installNtpServer {
  printInfo "Installing, configuring, and starting NTP..."

  sudo grep "NTP_SERVER_INSTALL" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo yum -y install ntp &>$LOGFILE || { printError; }
    sudo echo "NTP_SERVER_INSTALL" >> $INSTALLFILE
  fi

  sudo grep "NTP_SERVER_START" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo service ntpd start &>$LOGFILE || { printError; }
    sudo echo "NTP_SERVER_START" >> $INSTALLFILE
  fi

  printSuccess
}

# -- Database handling
function installMysqlTools {
  printInfo "Installing the MySQL-python tools..."

  sudo grep "MYSQL_TOOLS_INSTALL" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo yum -y install MySQL-python &>$LOGFILE || { printError; }
    sudo echo "MYSQL_TOOLS_INSTALL" >> $INSTALLFILE
  fi

  printSuccess
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
