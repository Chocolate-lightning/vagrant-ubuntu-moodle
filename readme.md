# Vagrant Ubuntu Moodle

This repository provides a template Vagrantfile to create a Moodle LAMP instance running a Ubuntu Trusty64 virtual machine 
using the VirtualBox software hypervisor. 
After setup is complete you will have a Moodle LAMP instance running on your local machine.

## Quick Start

First, make sure your development machine has
[VirtualBox](http://www.virtualbox.org)
installed. After this,
[download and install the appropriate Vagrant package for your OS](http://www.vagrantup.com/downloads).

Clone this project

    $ git clone git@github.com:troywilliams/vagrant-ubuntu-moodle.git mymoodleproject
    $ cd mymoodleproject


``vagrant up`` triggers vagrant to downloads the Ubuntu image (if necessary) and (re)launch the instance

``vagrant ssh`` connects you to the virtual machine. Configuration is stored in the directory so you can always return to this machine by executing vagrant ssh from the 
directory where the Vagrantfile was located.




MySQL root

    username: mysql
    password: mysql

Moodle administrator
    
    username: moodle
    password: moodle

```
$ vagrant up
```


