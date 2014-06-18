#!/bin/bash

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
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" user-create   --name="admin" --pass="$KEYSTONE_ADMIN_PASSWORD" --email="$KEYSTONE_ADMIN_EMAIL" &>$LOGFILE || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" role-create   --name="admin"                                                                   &>$LOGFILE || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" tenant-create --name="admin" --description="Admin Tenant"                                      &>$LOGFILE || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" user-role-add --user="admin" --tenant="admin" --role="admin"                                   &>$LOGFILE || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" user-role-add --user="admin" --role="_member_" --tenant="admin"                                &>$LOGFILE || { printError; }
    sudo echo "ADMIN_USER_ROLE_TENANT_CREATE" >> $INSTALLFILE
  fi

  # create a demo user, role and tenant
  sudo grep "DEMO_USER_ROLE_TENANT_CREATE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" user-create   --name="demo" --pass="$KEYSTONE_DEMO_PASSWORD" --email="$KEYSTONE_DEMO_EMAIL" &>$LOGFILE || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" tenant-create --name="demo" --description="Demo Tenant"                                     &>$LOGFILE || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" user-role-add --user="demo" --role="_member_" --tenant="demo"                               &>$LOGFILE || { printError; }
    sudo echo "DEMO_USER_ROLE_TENANT_CREATE" >> $INSTALLFILE
  fi

  # create a service tenant
  sudo grep "SERVICE_TENANT_CREATE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" tenant-create --name="service" --description="Service Tenant" &>$LOGFILE || { printError; }
    sudo echo "SERVICE_TENANT_CREATE" >> $INSTALLFILE
  fi

  printSuccess
}

# -- configure services and API endpoints
function defineServicesApiEndpoints {
  printInfo "Creating service and API endpoints..."

  # create admin user, role and tenant
  sudo grep "REGISTER_IDENTITY_SERVICE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" service-create --name="keystone" --type="identity" --description="OpenStack Identity" &>$LOGFILE || { printError; }
    sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" endpoint-create \
      --service-id=$(sudo keystone --os-token "$KEYSTONE_AUTH_TOKEN" --os-endpoint "http://controller:35357/v2.0" service-list | awk '/ identity / {print $2}') \
      --publicurl="http://controller:5000/v2.0"                                  \
      --internalurl="http://controller:5000/v2.0"                                \
      --adminurl="http://controller:35357/v2.0" &>$LOGFILE || { printError; }
    sudo echo "REGISTER_IDENTITY_SERVICE" >> $INSTALLFILE
  fi

  printSuccess
}

# -- populate an environment file that can be sourced and used for auth
function createKeystoneEnvironmentFile {
  printInfo "Creating Keystone environment file..."

  sudo grep "CREATE_KEYSTONERC_FILE" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    cat << EOF > /root/admin-openrc.sh
export OS_USERNAME=admin
export OS_PASSWORD=$KEYSTONE_ADMIN_PASSWORD
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://controller:35357/v2.0
EOF
    sudo echo "CREATE_KEYSTONERC_FILE" >> $INSTALLFILE
  fi

  printSuccess
}

# -- verify that the identity service installation was successful
function verifyIdentityServiceInstall {
  printInfo "Checking identity service installation..."

  sudo grep "CHECK_IDENTITY_SERVICE_INSTALL" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    # ensure that tokens can be retrieved using the RC file
    sudo -s /bin/bash -c "source /root/admin-openrc.sh && keystone token-get &>$LOGFILE" || { printError; }

    # ensure that the admin user has admin auth
    adminId=$(sudo -s /bin/bash -c "source /root/admin-openrc.sh && keystone user-list | grep admin"      | awk '{print $2}')
    userId=$(sudo  -s /bin/bash -c "source /root/admin-openrc.sh && keystone user-role-list | grep admin" | awk '{print $6}')
    if [[ $adminId != $userId ]]; then printError; fi

    sudo echo "CHECK_IDENTITY_SERVICE_INSTALL" >> $INSTALLFILE
  fi

  printSuccess
}
