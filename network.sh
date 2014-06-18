#!/bin/bash

source common.sh

# -- networking-related
checkNetworkNodeConnectivity

# -- NTP
installNtpClient

# -- database tools
installMysqlTools
