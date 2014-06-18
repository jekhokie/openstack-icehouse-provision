#!/bin/bash

# -- install required Python packages to install follow-on tools
function installPythonDeps {
  printInfo "Installing Python dependencies..."

  sudo grep "PYTHON_DEPS_INSTALL" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    installIfRequired python-setuptools
    #installIfRequired python-pip
    sudo echo "PYTHON_DEPS_INSTALL" >> $INSTALLFILE
  fi

  printSuccess
}

# -- install required client tools
function installCommandLineTools {
  printInfo "Installing command-line tools..."

  sudo grep "COMMAND_LINE_TOOLS_INSTALL" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    installIfRequired python-ceilometerclient
    installIfRequired python-cinderclient
    installIfRequired python-glanceclient
    installIfRequired python-heatclient
    installIfRequired python-keystoneclient
    installIfRequired python-neutronclient
    installIfRequired python-novaclient
    installIfRequired python-swiftclient
    installIfRequired python-troveclient
    sudo echo "COMMAND_LINE_TOOLS_INSTALL" >> $INSTALLFILE
  fi

  printSuccess
}
