#!/bin/bash

for file in $(ls lib/*); do source $file; done

# common functionality installed on each and every node

# -- prerequisites
installPrerequisites

# -- networking-related
configureIptables
configureHostsFile

# -- repositories
installRepoPackages
