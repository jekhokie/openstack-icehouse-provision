#!/bin/bash

# -- Database handling
function installMysqlTools {
  printInfo "Installing the MySQL-python tools..."

  sudo grep "MYSQL_TOOLS_INSTALL" $INSTALLFILE &>$LOGFILE
  if [[ $? -ne 0 ]]; then
    sudo yum -y install MySQL-python &>$LOGFILE || { printError; }
    sudo echo "MYSQL_TOOLS_INSTALL" >> $INSTALLFILE
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
