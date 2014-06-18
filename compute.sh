#!/bin/bash

source common.sh

# -- networking-related
checkComputeNodeConnectivity

# -- NTP
installNtpClient

# -- database tools
installMysqlTools
