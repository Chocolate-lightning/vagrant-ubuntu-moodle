#!/usr/bin/env bash

MYROOTUSER='mysql'
MYROOTPASS='mysql'

# Download and Install the Latest Updates for the OS.
apt-get update && apt-get upgrade -y
# Install Apache2.
apt-get install -y apache2 > /dev/null 2>&1
# Link /Vagrant directory to Apache Document root.
if ! [ -L /var/www ]; then
  rm -rf /var/www
  ln -fs /vagrant /var/www
fi

# Copy custom Apache2 site config over.
cp -f /vagrant/config/000-default.conf /etc/apache2/sites-enabled/
echo "ServerName localhost" | sudo tee /etc/apache2/conf-available/fqdn.conf
sudo a2enconf fqdn
service apache2 reload > /dev/null 2>&1
# Install any PHP and required modules.
apt-get -y install php5 \
                   php5-cli \
                   php-pear \
                   php5-curl \
                   php5-xmlrpc \
                   php5-gd \
                   php5-intl \
                   php5-json \
                   php5-mcrypt \
                   php5-dev > /dev/null 2>&1
# PHP Profiling
pecl install -f xhprof > /dev/null 2>&1
cp -f /vagrant/config/xhprof.ini /etc/php5/mods-available/
php5enmod xhprof > /dev/null 2>&1
apt-get -y install graphviz > /dev/null 2>&1

# Install MySQL.
echo "mysql-server-5.5 mysql-server/root_password password $MYROOTPASS" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $MYROOTPASS" | debconf-set-selections
apt-get -y install mysql-server-5.5 \
                   php5-mysql > /dev/null 2>&1
# Rename MySQL root user to keep simple.
echo "UPDATE mysql.user set user = '${MYROOTUSER}' where user = 'root'" | mysql -u root -p$MYROOTPASS
echo "FLUSH PRIVILEGES" | mysql -u root -p$MYROOTPASS

# Clean up
apt-get autoclean && apt-get clean

exit 0
