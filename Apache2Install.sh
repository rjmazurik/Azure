#!/bin/bash

sudo apt-get -y update & process_id=$!
# install Apache2
sudo apt-get -y install apache2 & wait $process_id
# write some HTML
sudo bash -c 'echo \<center\>\<h1\>My LB Test on $HOSTNAME\</h1\>\<br/\>\</center\> > /var/www/html/index.html'
# restart Apache
sudo apachectl restart
