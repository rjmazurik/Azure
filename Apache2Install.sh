#!/bin/bash
sudo apt-get update
# install Apache2
sudo apt-get install apache2
# write some HTML
echo \<center\>\<h1\>My LB Test on $HOSTNAME\</h1\>\<br/\>\</center\> > /var/www/html/index.html

# restart Apache
apachectl restart
