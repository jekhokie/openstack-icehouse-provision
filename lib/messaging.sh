#!/bin/bash

# -- messaging handling
function installAndConfigureQpid {
  printInfo "Installing, configuring, and starting Qpid Messaging..."

  sudo grep "QPID_INSTALL" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo yum -y install qpid-cpp-server &>$LOGFILE || { printError; }
    sudo echo "QPID_INSTALL" >> $INSTALLFILE
  fi
    
  sudo grep "QPID_CONFIGURE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo grep -E "^auth=no" /etc/qpidd.conf &>$LOGFILE
    if [[ $? -ne 0 ]]; then
      sudo grep -E "^auth" /etc/qpidd.conf &>$LOGFILE
      if [[ $? -ne 0 ]]; then
        sudo echo "auth=no" >> /etc/qpidd.conf || { printError; }
      else
        sudo sed -i "s/auth.*/auth=no/g" /etc/qpidd.conf &>$LOGFILE || { printError; }
      fi
    fi
    sudo echo "QPID_CONFIGURE" >> $INSTALLFILE
  fi

  sudo grep "QPID_START" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo service qpidd start &>$LOGFILE || { printError; }
    sudo chkconfig qpidd on  &>$LOGFILE || { printError; }
    sudo echo "QPID_START" >> $INSTALLFILE
  fi

  printSuccess
}
