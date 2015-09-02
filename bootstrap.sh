#!/usr/bin/env bash

MYROOTUSER='mysql'
MYROOTPASS='mysql'

DBTYPE='mysqli'
DBHOST='localhost'
DBNAME='moodle'
DBUSER='moodle'
DBPASS='moodle'
WWWROOT='http://localhost:8080'
DATAROOT='/data/moodle'

# Exit on detecting a Moodle config.php
if [ -f /vagrant/moodle/config.php ]; then
  echo Error : Detected existing Moodle config.php file, exiting
  exit 1
else
  echo OK : No Moodle config.php file, I\'m OK to go...
fi
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
echo "ServerName localhost" | sudo tee /etc/apache2/conf-available/servername.conf # TODO broken
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
php5enmod xhprof > /dev/null 2>&1
apt-get -y install graphviz > /dev/null 2>&1
# TODO need to set /usr/bin/dot in config.php

# Install MySQL.
echo "mysql-server-5.5 mysql-server/root_password password $MYROOTPASS" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $MYROOTPASS" | debconf-set-selections
apt-get -y install mysql-server-5.5 \
                   php5-mysql > /dev/null 2>&1
# Rename MySQL root user to keep simple.
echo "UPDATE mysql.user set user = '${MYROOTUSER}' where user = 'root'" | mysql -u root -p$MYROOTPASS
echo "FLUSH PRIVILEGES" | mysql -u root -p$MYROOTPASS

# Check if Moodle database exists.
if [ mysql -u $MYROOTUSER -p$MYROOTPASS -e "USE ${DBNAME}" > /dev/null 2>&1 ]; then
    echo Error : Detected existing Moodle database, exiting
    exit 1
else
    echo OK : No Moodle database, I\'m OK to go...
    #echo "DROP DATABASE IF EXISTS ${DBNAME}" | mysql -u $MYROOTUSER -p$MYROOTPASS
    echo "CREATE DATABASE moodle DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci" | mysql -u $MYROOTUSER -p$MYROOTPASS
    echo "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES,
          DROP, INDEX, ALTER ON ${DBNAME}.* TO ${DBUSER}@localhost IDENTIFIED BY '${DBPASS}'" | mysql -u $MYROOTUSER -p$MYROOTPASS
    echo "FLUSH PRIVILEGES" | mysql -u $MYROOTUSER -p$MYROOTPASS
    echo OK : Moodle database created yo
fi
service apache2 reload > /dev/null 2>&1
# Install Git.
apt-get install -y git > /dev/null 2>&1

# Get sauce.
GITREPO=git@github.com:moodle/moodle.git
GITBRANCH=master
if [ -f /vagrant/config/git.repo ]; then
    GITREPO=$(</vagrant/config/git.repo)
    if [ -f /vagrant/config/git.branch ]; then
        GITBRANCH=$(</vagrant/config/git.branch)
    fi
fi
# TODO maynot be github need to do some regex work.
ssh-keyscan -Ht rsa github.com >> ~/.ssh/known_hosts
if [ $GITBRANCH == 'master' ]; then
    git clone $GITREPO /vagrant/moodle
else
    git clone $GITREPO --branch $GITBRANCH /vagrant/moodle
fi
# Get code checker.
git clone git@github.com:moodlehq/moodle-local_codechecker.git /vagrant/moodle/local/codechecker
# Make Moodle dataroot.
if [ ! -d "$DATAROOT" ]; then
  mkdir -p $DATAROOT
  chmod -R 777 $DATAROOT
fi
# Install Moodle database.
php /vagrant/moodle/admin/cli/install.php --lang=en \
--non-interactive --agree-license --allow-unstable \
--wwwroot=${WWWROOT} \
--dataroot=${DATAROOT} \
--dbtype=${DBTYPE} \
--dbhost=${DBHOST} \
--dbname=${DBNAME} \
--dbuser=${DBUSER} \
--dbpass=${DBPASS} \
--prefix=mdl_ \
--shortname="Site shortname - CHANGEME" \
--fullname="Site fullname - CHANGEME" \
--summary="Site summary - CHANGEME" \
--adminuser="moodle" \
--adminpass="moodle" \
--adminemail="moodle@localhost.invalid"

# Replace the Moodle generated config with our config.
cp -f /vagrant/config/config.php /vagrant/moodle/
chmod o+r /vagrant/moodle/config.php

sed -i "s|{{dbtype}}|${DBTYPE}|" /vagrant/moodle/config.php
sed -i "s|{{dbhost}}|${DBHOST}|" /vagrant/moodle/config.php
sed -i "s|{{dbname}}|${DBNAME}|" /vagrant/moodle/config.php
sed -i "s|{{dbuser}}|${DBUSER}|" /vagrant/moodle/config.php
sed -i "s|{{dbpass}}|${DBPASS}|" /vagrant/moodle/config.php
sed -i "s|{{wwwroot}}|${WWWROOT}|" /vagrant/moodle/config.php
sed -i "s|{{dataroot}}|${DATAROOT}|" /vagrant/moodle/config.php

# Clean up
apt-get autoclean && apt-get clean

exit 0
