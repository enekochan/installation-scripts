#!/bin/bash

#
# MacPorts, Apache 2, MySQL 5, PHP 5.3 and phpMyAdmin 3.5.4 installation script for Mac OS X
#
# Author: enekochan
# URL: http://tech.enekochan.com
#
# It is mandatory to have installed:
# - Apple Xcode Developer Tools
# - Apple Command Line Developer Tools
# Download them from http://connect.apple.com/ (Apple ID is needed)
# Once installed run this command to accept the EULA:
# 
# $ xcodebuild -license
#
################################################################################
# Important file locations
################################################################################
# httpd.conf:         /opt/local/apache2/conf/httpd.conf
# httpd-vhosts.conf:  /opt/local/apache2/conf/extra/httpd-vhosts.conf
# htdocs folder:      /opt/local/apache2/htdocs
# my.cnf:             /opt/local/my.cnf
# php.ini:            /opt/local/etc/php5/php.ini
# config.inc.php:     /opt/local/apache2/htdocs/phpmyadmin/config.inc.php
################################################################################
#
# Ref: http://gillesfabio.com/blog/2010/12/17/getting-php-5-3-on-mac-os-x/
#
################################################################################

function readPrompt() {
  while true; do
    read -e -p "$1 (default $2)"": " result
    case $result in
      Y|y ) result="y"; break;;
      N|n ) result="n"; break;;
      "" ) result=`echo $2 | awk '{print substr($0,0,1)}'`; break;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

# If you want to completely uninstall MacPorts and all installed ports
# use the "uninstall" parameter
if [ "$1" == "uninstall" ]; then
  echo "Uninstalling MacPorts and all installed ports..."
  sudo port -fp uninstall installed
  sudo rm -rf \
    /opt/local \
    /Applications/DarwinPorts \
    /Applications/MacPorts \
    /Library/LaunchDaemons/org.macports.* \
    /Library/Receipts/DarwinPorts*.pkg \
    /Library/Receipts/MacPorts*.pkg \
    /Library/StartupItems/DarwinPortsStartup \
    /Library/Tcl/darwinports1.0 \
    /Library/Tcl/macports1.0 \
    ~/.macports
  exit
fi

readPrompt "Do you want Apache 2 and MySQL 5 to autorun on boot? " "y"
AUTORUN=$result

readPrompt "Do you want to secure MySQL 5? (MySQL password for root user will be changed in this interactive process) " "y"
SECURE=$result

readPrompt "Do you want to change Apache 2 proccess running user and group to your user and group? " "y"
CHANGE_USER=$result

readPrompt "Do you want to set Apache 2 ServerName to 127.0.0.1:80? " "y"
CHANGE_SERVER_NAME=$result

readPrompt "Do you want to activate virtual hosts in Apache 2? " "y"
ACTIVATE_VIRTUAL_HOSTS=$result

readPrompt "Do you want to create virtual hosts for localhost? " "y"
LOCALHOST_VIRTUAL_HOST=$result

# Download the MacPort software for the currern Mac OS X version
# Manual download in http://www.macports.org/install.php
VERSION=`sw_vers -productVersion`
VERSION=${VERSION:3:1}
if [ "$VERSION" == "6" ]; then
  URL=https://distfiles.macports.org/MacPorts/MacPorts-2.2.1-10.6-SnowLeopard.pkg
elif [ "$VERSION" == "7" ]; then
  URL=https://distfiles.macports.org/MacPorts/MacPorts-2.2.1-10.7-Lion.pkg
elif [ "$VERSION" == "8" ]; then
  URL=https://distfiles.macports.org/MacPorts/MacPorts-2.2.1-10.8-MountainLion.pkg
elif [ "$VERSION" == "9" ]; then
  URL=https://distfiles.macports.org/MacPorts/MacPorts-2.2.1-10.9-Mavericks.pkg
fi
if [ "$URL" == "" ]; then
  echo "MacPort can only be installed automatically in Mac OS X 10.6, 10.7, 10.8 or 10.9"
  exit
fi
curl -O $URL
FILE_NAME=`echo $URL | sed -e "s/\https:\/\/distfiles.macports.org\/MacPorts\///g"`
sudo installer -pkg $FILE_NAME -target /

# Update MacPorts package database
sudo port -d selfupdate

# Install Apache 2
sudo port install apache2

if [ $AUTORUN == "y" ]; then
  # Make Apache 2 autorun on boot
  # This creates the file /Library/LaunchDaemons/org.macports.apache2.plist
  # and a /opt/local/bin/daemondo process to manage it.
  sudo port load apache2
else
  # Run the Apache 2 service
  sudo /opt/local/etc/LaunchDaemons/org.macports.apache2/apache2.wrapper start
fi

# Install MySQL 5
sudo port install mysql5-server

# Configure the MySQL 5 database files and folders
sudo -u _mysql mysql_install_db5
sudo chown -R mysql:mysql /opt/local/var/db/mysql5/
sudo chown -R mysql:mysql /opt/local/var/run/mysql5/
sudo chown -R mysql:mysql /opt/local/var/log/mysql5/

# Remain compatible with other programs that may look for the socket file in its original location
sudo ln -s /tmp/mysql.sock /opt/local/var/run/mysql5/mysqld.sock

# Create a my.cnf file from the "small" template
# It can also be copied to /etc/my.cnf or /opt/local/var/db/mysql5/my.cnf (deprecated)
# This file should be in /opt/local/etc/mysql/my.cnf but /opt/local/share/mysql5/mysql/mysql.server
# MySQL daemon start/stop script looks for it (in this order) in /etc/my.cnf, /opt/local/my.cnf
# and /opt/local/var/db/mysql5/my.cnf. If you look the script it uses the $basedir and $datadir
# variables to search it.
sudo cp /opt/local/share/mysql5/mysql/my-small.cnf /opt/local/my.cnf

if [ $AUTORUN == "y" ]; then
  # Make MySQL 5 autorun on boot
  # This creates the file /Library/LaunchDaemons/org.macports.mysql5.plist
  # and a /opt/local/bin/daemondo process to manage it.
  sudo port load mysql5-server
else
  # Run the MySQL 5 service
  sudo /opt/local/etc/LaunchDaemons/org.macports.mysql5/mysql5.wrapper start
fi

# Secure MySQL 5 configuration
# root password in blank by default
# This is an optional step that changes root password, deletes anonymous users,
# disables remote logins for root user and deletes the test database
# If you only want to change root password run this command:
# $ mysqladmin5 -u root -p password <your-password>
if [ $SECURE == "y" ]; then
  /opt/local/bin/mysql_secure_installation5
fi

# Install PHP 5.3
sudo port install php5 +apache2 +pear
# You can add mire php5 extension. Run `port search php5-` to see available extensions
sudo port install php5-mysql php5-sqlite php5-xdebug php5-mbstring php5-iconv php5-posix php5-apc php5-mcrypt

# Register PHP 5.3 with Apache 2
cd /opt/local/apache2/modules
sudo /opt/local/apache2/bin/apxs -a -e -n "php5" libphp5.so

# Create the php.ini file from the development template
cd /opt/local/etc/php5
sudo cp php.ini-development php.ini

# Configure the timezone and the socket of MySQL in /opt/local/etc/php5/php.ini
TIMEZONE=`systemsetup -gettimezone | awk '{ print $3 }'`
TIMEZONE=$(printf "%s\n" "$TIMEZONE" | sed 's/[][\.*^$/]/\\&/g')
sudo sed \
  -e "s/;date.timezone =/date.timezone = \"$TIMEZONE\"/g" \
  -e "s#pdo_mysql\.default_socket.*#pdo_mysql\.default_socket=`/opt/local/bin/mysql_config5 --socket`#" \
  -e "s#mysql\.default_socket.*#mysql\.default_socket=`/opt/local/bin/mysql_config5 --socket`#" \
  -e "s#mysqli\.default_socket.*#mysqli\.default_socket=`/opt/local/bin/mysql_config5 --socket`#" \
  php.ini > /tmp/php.ini
sudo chown root:admin /tmp/php.ini
sudo mv /tmp/php.ini ./

# Include PHP 5.3 in Apache 2 configuration
sudo echo "" | sudo tee -a /opt/local/apache2/conf/httpd.conf
sudo echo "Include conf/extra/mod_php.conf" | sudo tee -a /opt/local/apache2/conf/httpd.conf

if [ $CHANGE_USER == "y" ]; then
  # Change the user and group of the Apache 2 proccess to current user
  # By default it is www:www
  sudo sed \
    -e 's/User www/User `id -un`/g' \
    -e 's/Group www/Group `id -gn`/g' \
    /opt/local/apache2/conf/httpd.conf > /tmp/httpd.conf
  sudo chown root:admin /tmp/httpd.conf
  sudo mv /tmp/httpd.conf /opt/local/apache2/conf/httpd.conf
fi

if [ $CHANGE_SERVER_NAME == "y" ]; then
  # This solves this warning:
  # httpd: Could not reliably determine the server's fully qualified domain name, using enekochans-Mac-mini.local for ServerName
  # Just fill ServerName option in httpd.conf with 127.0.0.1:80
  sudo sed \
    -e 's/#ServerName www.example.com:80/ServerName 127.0.0.1:80/g' \
    /opt/local/apache2/conf/httpd.conf > /tmp/httpd.conf
  sudo chown root:admin /tmp/httpd.conf
  sudo mv /tmp/httpd.conf /opt/local/apache2/conf/httpd.conf
fi

if [ $ACTIVATE_VIRTUAL_HOSTS == "y" ]; then
  sudo sed \
    -e 's/#Include conf\/extra\/httpd-vhosts.conf/Include conf\/extra\/httpd-vhosts.conf/g' \
    /opt/local/apache2/conf/httpd.conf > /tmp/httpd.conf
  sudo chown root:admin /tmp/httpd.conf
  sudo mv /tmp/httpd.conf /opt/local/apache2/conf/httpd.conf
fi

if [ $LOCALHOST_VIRTUAL_HOST ]; then
  echo "" | sudo tee -a /opt/local/apache2/conf/extra/httpd-vhosts.conf
  echo "<VirtualHost *:80>" | sudo tee -a /opt/local/apache2/conf/extra/httpd-vhosts.conf
  echo "    ServerAdmin webmaster@localhost" | sudo tee -a /opt/local/apache2/conf/extra/httpd-vhosts.conf
  echo "    DocumentRoot \"/opt/local/apache2/htdocs\"" | sudo tee -a /opt/local/apache2/conf/extra/httpd-vhosts.conf
  echo "    ServerName localhost" | sudo tee -a /opt/local/apache2/conf/extra/httpd-vhosts.conf
  echo "    ServerAlias localhost" | sudo tee -a /opt/local/apache2/conf/extra/httpd-vhosts.conf
  echo "    ErrorLog \"logs/localhost-error_log\"" | sudo tee -a /opt/local/apache2/conf/extra/httpd-vhosts.conf
  echo "    CustomLog \"logs/localhost-access_log\" common" | sudo tee -a /opt/local/apache2/conf/extra/httpd-vhosts.conf
  echo "    DirectoryIndex index.php index.html" | sudo tee -a /opt/local/apache2/conf/extra/httpd-vhosts.conf
  echo "</VirtualHost>" | sudo tee -a /opt/local/apache2/conf/extra/httpd-vhosts.conf
  echo "" | sudo tee -a /opt/local/apache2/conf/extra/httpd-vhosts.conf
fi

# Install phpMyAdmin in localhost (http://localhost/phpmyadmin)
cd /opt/local/apache2/htdocs
sudo curl --location -O http://sourceforge.net/projects/phpmyadmin/files/phpMyAdmin/3.5.4/phpMyAdmin-3.5.4-all-languages.tar.gz
tar xzvpf phpMyAdmin-3.5.4-all-languages.tar.gz
#sudo rm phpMyAdmin-3.5.4-all-languages.tar.gz
sudo mv phpMyAdmin-3.5.4-all-languages phpmyadmin
cd phpmyadmin
sudo cp config.sample.inc.php config.inc.php
echo "Enter MySQL's root password."
mysql5 -u root -p < examples/create_tables.sql
read -e -p "Enter a password for pma user in phpmyadmin database"": " result
PMA_PASSWORD=$result
echo "GRANT USAGE ON mysql.* TO 'pma'@'localhost' IDENTIFIED BY '$PMA_PASSWORD';" > /tmp/grant.sql
echo "GRANT SELECT (" >> /tmp/grant.sql
echo "    Host, User, Select_priv, Insert_priv, Update_priv, Delete_priv," >> /tmp/grant.sql
echo "    Create_priv, Drop_priv, Reload_priv, Shutdown_priv, Process_priv," >> /tmp/grant.sql
echo "    File_priv, Grant_priv, References_priv, Index_priv, Alter_priv," >> /tmp/grant.sql
echo "    Show_db_priv, Super_priv, Create_tmp_table_priv, Lock_tables_priv," >> /tmp/grant.sql
echo "    Execute_priv, Repl_slave_priv, Repl_client_priv" >> /tmp/grant.sql
echo "    ) ON mysql.user TO 'pma'@'localhost';" >> /tmp/grant.sql
echo "GRANT SELECT ON mysql.db TO 'pma'@'localhost';" >> /tmp/grant.sql
echo "GRANT SELECT ON mysql.host TO 'pma'@'localhost';" >> /tmp/grant.sql
echo "GRANT SELECT (Host, Db, User, Table_name, Table_priv, Column_priv)" >> /tmp/grant.sql
echo "    ON mysql.tables_priv TO 'pma'@'localhost';" >> /tmp/grant.sql
echo "GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost';" >> /tmp/grant.sql
echo "FLUSH PRIVILEGES;" >> /tmp/grant.sql
echo "Enter MySQL's root password."
mysql5 -u root -p < /tmp/grant.sql
rm /tmp/grant.sql

# Fill the blowfish_secret password with random value,
# uncomment all lines with "$cfg['Servers'][$i]", change pma users password
# comment back the Swekey authentication configuration line
BLOWFISH1=$(printf "%s\n" "\$cfg['blowfish_secret']" | sed 's/[][\.*^$/]/\\&/g')
PASS=`env LC_CTYPE=C tr -dc "a-zA-Z0-9-_\$\?\{\}\=\^\+\(\)\@\%\|\*\[\]\~" < /dev/urandom | head -c 46`
BLOWFISH2=$(printf "%s\n" "\$cfg['blowfish_secret'] = '$PASS';" | sed 's/[][\.*^$/]/\\&/g')
TEXT1=$(printf "%s\n" "// \$cfg['Servers'][\$i]" | sed 's/[][\.*^$/]/\\&/g')
TEXT2=$(printf "%s\n" "\$cfg['Servers'][\$i]" | sed 's/[][\.*^$/]/\\&/g')
sudo sed \
  -e "s/^$BLOWFISH1.*/$BLOWFISH2/g" \
  -e "s/$TEXT1/$TEXT2/g" \
  -e "s/pmapass/$PMA_PASSWORD/g" \
  -e "/swekey-pma.conf/s/^/\/\/ /" \
  /opt/local/apache2/htdocs/phpmyadmin/config.inc.php > /tmp/config.inc.php
sudo chown root:admin /tmp/config.inc.php
sudo mv /tmp/config.inc.php /opt/local/apache2/htdocs/phpmyadmin/config.inc.php

PMA_PASSWORD=""
PASS=""
BLOWFISH2=""

# Restart Apache 2
sudo /opt/local/apache2/bin/apachectl -k restart
