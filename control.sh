#!/bin/bash

# -- check connectivity for network configurations
function checkControllerNodeConnectivity {
  printInfo "Checking network connectivity to required locations..."

  sudo grep "NETWORK_CONN_CHECK" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    ping -c 1 openstack.org &>$LOGFILE || { printError; }
    ping -c 1 network       &>$LOGFILE || { printError; }
    ping -c 1 compute1      &>$LOGFILE || { printError; }
    sudo echo "NETWORK_CONN_CHECK" >> $INSTALLFILE
  fi

  printSuccess
}

# -- MySQL database handling
function installAndConfigureMysql {
  printInfo "Installing, configuring, starting, and securing MySQL..."

  # install and start services if not yet installed
  sudo grep "MYSQL_INSTALL" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo yum -y install mysql mysql-server mysql-libs MySQL-python &>$LOGFILE || { printError; }

    sudo grep -E "^bind-address=$CONTROLLER_IP" /etc/my.cnf &>$LOGFILE
    if [[ $? -ne 0 ]]; then
      sudo sed -i "s/\[mysqld\]\(.*\)/[mysqld]\nbind-address=$CONTROLLER_IP\ndefault-storage-engine=innodb\ninnodb_file_per_table\ncollation-server=utf8_general_ci\ninit-connect='SET NAMES utf8'\ncharacter-set-server=utf8\n\1/" /etc/my.cnf &>$LOGFILE || { printError; }
    fi

    sudo service mysqld start &>$LOGFILE || { printError; }
    sudo chkconfig mysqld on  &>$LOGFILE || { printError; }
    sudo mysql_install_db     &>$LOGFILE || { printError; }

    sudo echo "MYSQL_INSTALL" >> $INSTALLFILE
  fi

  # secure the MySQL installation if it has not yet been secured
  sudo grep "MYSQL_SECURE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo /usr/bin/mysql -u root --password="" -e "DROP USER ''@'localhost';"                                                &>$LOGFILE || { printError; }
    sudo /usr/bin/mysql -u root --password="" -e "DROP USER ''@'controller';"                                               &>$LOGFILE || { printError; }
    sudo /usr/bin/mysql -u root --password="" -e "DELETE FROM mysql.db WHERE Db LIKE 'test%';"                              &>$LOGFILE || { printError; }
    sudo /usr/bin/mysql -u root --password="" -e "DROP DATABASE test;"                                                      &>$LOGFILE || { printError; }
    sudo /usr/bin/mysql -u root --password="" -e "SET PASSWORD FOR 'root'@'controller' = PASSWORD('$MYSQL_ROOT_PASSWORD');" &>$LOGFILE || { printError; }
    sudo /usr/bin/mysql -u root --password="" -e "SET PASSWORD FOR 'root'@'127.0.0.1'  = PASSWORD('$MYSQL_ROOT_PASSWORD');" &>$LOGFILE || { printError; }
    sudo /usr/bin/mysql -u root --password="" -e "SET PASSWORD FOR 'root'@'localhost'  = PASSWORD('$MYSQL_ROOT_PASSWORD');" &>$LOGFILE || { printError; }
    sudo /usr/bin/mysql -u root --password="$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"                                    &>$LOGFILE || { printError; }
    sudo echo "MYSQL_SECURE" >> $INSTALLFILE
  fi

  printSuccess
}

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

# -- identity service
function installAndConfigureKeystone {
  printInfo "Installing and configuring Keystone..."

  sudo grep "KEYSTONE_INSTALL" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo yum -y install openstack-keystone python-keystoneclient &>$LOGFILE || { printError; }
    sudo echo "KEYSTONE_INSTALL" >> $INSTALLFILE
  fi

  sudo grep "KEYSTONE_CONFIGURE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    /usr/bin/openstack-config --set /etc/keystone/keystone.conf database connection mysql://keystone:$KEYSTONE_DB_PASSWORD@controller/keystone &>$LOGFILE || { printError; }
    sudo echo "KEYSTONE_CONFIGURE" >> $INSTALLFILE
  fi

  # configure privileges and identity databases
  sudo grep "KEYSTONE_DB_CONFIGURE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo /usr/bin/mysql -u root --password="$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE keystone;"                                                                           &>$LOGFILE || { printError; }
    sudo /usr/bin/mysql -u root --password="$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DB_PASSWORD';" &>$LOGFILE || { printError; }
    sudo /usr/bin/mysql -u root --password="$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DB_PASSWORD';"         &>$LOGFILE || { printError; }
    sudo su -s /bin/sh -c "keystone-manage db_sync" keystone                                                                                                               &>$LOGFILE || { printError; }
    sudo echo "KEYSTONE_DB_CONFIGURE" >> $INSTALLFILE
  fi

  # configure PKI
  sudo grep "KEYSTONE_PKI" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $KEYSTONE_AUTH_TOKEN &>$LOGFILE || { printError; }
    sudo keystone-manage pki_setup --keystone-user keystone --keystone-group keystone                &>$LOGFILE || { printError; }
    sudo chown -R keystone:keystone /etc/keystone/ssl                                                &>$LOGFILE || { printError; }
    sudo chmod -R o-rwx /etc/keystone/ssl                                                            &>$LOGFILE || { printError; }
    sudo echo "KEYSTONE_PKI" >> $INSTALLFILE
  fi

  # start the service
  sudo grep "KEYSTONE_START" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo service openstack-keystone start &>$LOGFILE || { printError; }
    sudo chkconfig openstack-keystone on  &>$LOGFILE || { printError; }
    sudo echo "KEYSTONE_START" >> $INSTALLFILE
  fi

  # configure cron job
  sudo grep "KEYSTONE_TOKEN_FLUSH_CRON" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo crontab -l -u keystone 2>&1 | grep -q token_flush
    if [[ $? -ne 0 ]]; then
      sudo echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/keystone || { printError; }
    fi
    sudo echo "KEYSTONE_TOKEN_FLUSH_CRON" >> $INSTALLFILE
  fi

  printSuccess
}

# -- configure identity service users, tenants and roles
function defineUsersTenantsRoles {
  printInfo "Creating required users, tenants and roles..."

  # create admin user, role and tenant
  sudo grep "ADMIN_USER_ROLE_TENANT_CREATE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" user-create   --name="admin" --pass="$KEYSTONE_ADMIN_PASSWORD" --email="$KEYSTONE_ADMIN_EMAIL" &>/dev/null || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" role-create   --name="admin"                                                                   &>/dev/null || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" tenant-create --name="admin" --description="Admin Tenant"                                      &>/dev/null || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" user-role-add --user="admin" --tenant="admin" --role="admin"                                   &>/dev/null || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" user-role-add --user="admin" --role="_member_" --tenant="admin"                                &>/dev/null || { printError; }
    sudo echo "ADMIN_USER_ROLE_TENANT_CREATE" >> $INSTALLFILE
  fi

  # create a demo user, role and tenant
  sudo grep "DEMO_USER_ROLE_TENANT_CREATE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" user-create   --name="demo" --pass="$KEYSTONE_DEMO_PASSWORD" --email="$KEYSTONE_DEMO_EMAIL" &>/dev/null || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" tenant-create --name="demo" --description="Demo Tenant"                                     &>/dev/null || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" user-role-add --user="demo" --role="_member_" --tenant="demo"                               &>/dev/null || { printError; }
    sudo echo "DEMO_USER_ROLE_TENANT_CREATE" >> $INSTALLFILE
  fi

  # create a service tenant
  sudo grep "SERVICE_TENANT_CREATE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" tenant-create --name="service" --description="Service Tenant" &>/dev/null || { printError; }
    sudo echo "SERVICE_TENANT_CREATE" >> $INSTALLFILE
  fi

  printSuccess
}
