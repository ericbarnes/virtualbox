#!/usr/bin/env bash

# Configuration
MY_IP=192.168.0.10
MY_SUBNET=24
MY_MYSQL_ROOT_PASSWORD=secret

print_info () {

	local s=$1
 
	echo "#################################################"
	echo "$1"
	echo "#################################################"
}

print_info "Updating the base OS"

# Upgrade Base Packages
sudo apt-get update
sudo apt-get upgrade -y

print_info "Installing Web Packages"

# Install Web Packages
sudo apt-get install -y build-essential dkms re2c apache2 php5 php5-dev php-pear php5-xdebug php5-apcu php5-json php5-sqlite \
php5-mysql php5-pgsql php5-gd curl php5-curl memcached php5-memcached libmcrypt4 php5-mcrypt postgresql redis-server beanstalkd \
openssh-server git vim python2.7-dev

print_info "Downloading Bash Aliases"

# Download Bash Aliases
wget -O ~/.bash_aliases https://raw2.github.com/taylorotwell/virtualbox/master/aliases

print_info "Setting Apache Server Name"

# Set Apache ServerName
sudo sed -i "s/#ServerRoot.*/ServerName ubuntu/" /etc/apache2/apache2.conf
sudo /etc/init.d/apache2 restart

print_info "Installing MySQL"

# Install MySQL
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password secret'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password secret'
sudo apt-get -y install mysql-server

print_info "Configuring Postgres"

# Configure Postgres
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.1/main/postgresql.conf
echo "host    all             all             $MY_IP/$MY_SUBNET               md5" | sudo tee -a /etc/postgresql/9.1/main/pg_hba.conf
sudo -u postgres psql -c "CREATE ROLE eric LOGIN UNENCRYPTED PASSWORD 'secret' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"
sudo -u postgres /usr/bin/createdb --echo --owner=eric laravel
sudo service postgresql restart

print_info "Configuring MySQL"

# Configure MySQL
sudo sed -i '/^bind-address/s/bind-address.*=.*/bind-address = $MY_IP/' /etc/mysql/my.cnf
mysql -u root -p mysql -e "GRANT ALL ON *.* TO root@'$MY_IP' IDENTIFIED BY '$MY_MYSQL_ROOT_PASSWORD';"
sudo service mysql restart

print_info "Configuring Mcrypt"

# Configure Mcrypt (Ubuntu 13.10)
sudo ln -s /etc/php5/conf.d/mcrypt.ini /etc/php5/mods-available
sudo php5enmod mcrypt
sudo service apache2 restart

print_info "Installing Composer"

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

print_info "Installing PHPUnit"

# Install PHPUnit
sudo pear config-set auto_discover 1
sudo pear install pear.phpunit.de/phpunit

print_info "Installing Mailparse"

# Install Mailparse (For Snappy)
sudo pecl install mailparse
echo "extension=mailparse.so" | sudo tee -a /etc/php5/apache2/php.ini

print_info "Enabling PHP Error Reporting"

# Enable PHP Error Reporting
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php5/cli/php.ini

print_info "Generating SSH Keys"

# Generate SSH Key
cd ~
mkdir .ssh
cd ~/.ssh
ssh-keygen -f id_rsa -t rsa -N ''

print_info "Setting up Authorised Keys"

# Setup Authorized Keys
cd ~/.ssh
wget https://raw2.github.com/taylorotwell/virtualbox/master/authorized_keys

print_info "Installing Git Subtree"

# Install Git Subtree
cd ~
git clone https://github.com/apenwarr/git-subtree
cd ~/git-subtree
sudo sh install.sh
cd ~
rm -rf git-subtree/

print_info "Installing Git Subsplit"

# Install Git Subsplit
git clone https://github.com/dflydev/git-subsplit
cd ~/git-subsplit
sudo sh install.sh
cd ~
rm -rf git-subsplit/

print_info "Configuring and Starting Beanstalked Queue"

# Configure & Start Beanstalkd Queue
sudo sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd
sudo /etc/init.d/beanstalkd start

print_info "Installing Fabri and Hipchart Plugin"

# Install Fabric & Hipchat Plugin
sudo apt-get install -y python-pip
sudo pip install fabric
sudo pip install python-simple-hipchat

print_info "Installing NodeJS"

# Install NodeJs
cd ~
wget http://nodejs.org/dist/v0.10.24/node-v0.10.24.tar.gz
tar -xvf node-v0.10.24.tar.gz
cd node-v0.10.24
./configure
make
sudo make install
cd ~
rm ~/node-v0.10.24.tar.gz
rm -rf ~/node-v0.10.24

print_info "Installing Grunt"

# Install Grunt
sudo npm install -g grunt-cli

print_info "Installing Forever"

# Install Forever
sudo npm install -g forever

print_info "Creating Script Directory"

# Create Scripts Directory
mkdir ~/Scripts
mkdir ~/Scripts/PhpInfo

print_info "Downloading Serve Script"

# Download Serve Script
cd ~/Scripts
wget https://raw2.github.com/taylorotwell/virtualbox/master/serve.sh

print_info "Downloading Release Scripts"

# Download Release Scripts
cd ~/Scripts
wget https://raw2.github.com/taylorotwell/virtualbox/master/release-scripts/illuminate-split-full.sh
wget https://raw2.github.com/taylorotwell/virtualbox/master/release-scripts/illuminate-split-heads.sh
wget https://raw2.github.com/taylorotwell/virtualbox/master/release-scripts/illuminate-split-tags.sh
wget https://raw2.github.com/taylorotwell/virtualbox/master/release-scripts/illuminate-split-single.sh

print_info "Creating PHP Info Page"

# Build PHP Info Site
echo "<?php phpinfo();" > ~/Scripts/PhpInfo/index.php

print_info "Configuring Apache Virtual Hosts"

# Configure Apache Hosts
sudo a2enmod rewrite
echo "127.0.0.1  info.app" | sudo tee -a /etc/hosts
vhost="<VirtualHost *:80>
     ServerName info.app
     DocumentRoot /home/eric/Scripts/PhpInfo
     <Directory \"/home/eric/Scripts/PhpInfo\">
          Order allow,deny
          Allow from all
          Require all granted
          AllowOverride All
    </Directory>
</VirtualHost>"
echo "$vhost" | sudo tee /etc/apache2/sites-available/info.app.conf
sudo a2ensite info.app
sudo /etc/init.d/apache2 restart

print_info "Installing Beanstaked Console"

# Install Beanstalkd Console
cd ~/Scripts
git clone https://github.com/ptrofimov/beanstalk_console.git Beansole
vhost="<VirtualHost *:80>
     ServerName beansole.app
     DocumentRoot /home/eric/Scripts/Beansole/public
     <Directory \"/home/eric/Scripts/Beansole/public\">
          Order allow,deny
          Allow from all
          Require all granted
          AllowOverride All
    </Directory>
</VirtualHost>"
echo "$vhost" | sudo tee /etc/apache2/sites-available/beansole.app.conf
sudo a2ensite beansole.app
sudo /etc/init.d/apache2 restart

print_info "Installing VirtualBox Guest Additions"

# VirtualBox Guest Additions
sudo mount /dev/cdrom /media/cdrom
sudo sh /media/cdrom/VBoxLinuxAdditions.run
sudo usermod -aG vboxsf www-data
sudo usermod -aG vboxsf eric

print_info "Preforming Final Clean Up"

# Final Clean
cd ~
rm -rf tmp/

print_info "System is Going for a Reboot..."

# Reboot
sudo reboot
