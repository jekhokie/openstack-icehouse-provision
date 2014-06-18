#!/bin/bash

source common.sh

# -- networking-related
checkControllerNodeConnectivity

# -- NTP
installNtpServer

# -- database
installAndConfigureMysql

# -- repositories
installRepoPackages

# -- messaging
installAndConfigureQpid

# -- Keystone
installAndConfigureKeystone
defineUsersTenantsRoles
defineServicesApiEndpoints
createKeystoneEnvironmentFile
verifyIdentityServiceInstall
