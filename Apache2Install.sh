#!/bin/bash

apt-get -y update
# install Apache2
apt-get -y install apache2
# write some HTML
sudo bash -c 'echo \<center\>\<h1\>My LB Test on $HOSTNAME\</h1\>\<br/\>\</center\> > /var/www/html/index.html'
# restart Apache
apachectl restart
