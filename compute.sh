#!/bin/bash

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
