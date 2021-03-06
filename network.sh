#!/bin/bash

source common.sh

# -- prerequisites
installPrerequisites

# -- networking-related
configureIptables
configureHostsFile
checkNetworkNodeConnectivity

# -- repositories
installRepoPackages

# -- NTP
installNtpClient

# -- database tools
installMysqlTools

# -- OpenStack command-line clients
installPythonDeps
installCommandLineTools
