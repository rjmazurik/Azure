#!/bin/bash

sudo apt-get -y update
# install Apache2
sudo apt-get -y install apache2
# write some HTML
sudo bash -c 'echo \<center\>\<h1\>My LB Test on $HOSTNAME\</h1\>\<br/\>\</center\> > /var/www/html/index.html'
# restart Apache
sudo apachectl restart
