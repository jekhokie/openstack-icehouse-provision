# -- common globals
LOGFILE="logs/console.log"
INSTALLFILE="/root/openstack-install.status"

# -- helper functions
function printInfo {
  printf "%-70s" "$1"
}

function printSuccess {
  echo -e "[ \e[92mdone\e[0m ]"
}

function printError {
  echo -e "[ \e[91mfail\e[0m ]"
  exit 1
}

# -- install a package if it is not yet installed
# -- Inputs:
# --- $1 - Name of Package
# --- $2 - (Optional) path to Package to install
function installIfRequired {
  sudo rpm -qi $1 &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    if [ ! -z $2 ]; then
      sudo yum -y install $2 &>$LOGFILE || { printError; }
    else
      sudo yum -y install $1 &>$LOGFILE || { printError; }
    fi
  fi
}
