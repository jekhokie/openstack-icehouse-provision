#!/bin/bash

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
