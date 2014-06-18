#!/bin/bash

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

# -- check connectivity for network configurations
function checkComputeNodeConnectivity {
  printInfo "Checking network connectivity to required locations..."

  sudo grep "NETWORK_CONN_CHECK" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    ping -c 1 openstack.org      &>$LOGFILE || { printError; }
    ping -c 1 controller         &>$LOGFILE || { printError; }
    ping -c 1 $NETWORK_TUNNEL_IP &>$LOGFILE || { printError; }
    sudo echo "NETWORK_CONN_CHECK" >> $INSTALLFILE
  fi

  printSuccess
}

function checkNetworkNodeConnectivity {
  printInfo "Checking network connectivity to required locations..."

  sudo grep "NETWORK_CONN_CHECK" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    ping -c 1 openstack.org       &>$LOGFILE || { printError; }
    ping -c 1 controller          &>$LOGFILE || { printError; }
    ping -c 1 $COMPUTE1_TUNNEL_IP &>$LOGFILE || { printError; }
    sudo echo "NETWORK_CONN_CHECK" >> $INSTALLFILE
  fi

  printSuccess
}

function checkControllerNodeConnectivity {
  printInfo "Checking network connectivity to required locations..."

  sudo grep "NETWORK_CONN_CHECK" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    ping -c 1 openstack.org &>$LOGFILE || { printError; }
    ping -c 1 network       &>$LOGFILE || { printError; }
    ping -c 1 compute1      &>$LOGFILE || { printError; }
    sudo echo "NETWORK_CONN_CHECK" >> $INSTALLFILE
  fi

  printSuccess
}
