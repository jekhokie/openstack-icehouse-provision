#!/bin/bash

source common.sh

# -- prerequisites
installPrerequisites

# -- networking-related
configureIptables
configureHostsFile
checkControllerNodeConnectivity

# -- repositories
installRepoPackages

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

# -- OpenStack command-line clients
installPythonDeps
installCommandLineTools
