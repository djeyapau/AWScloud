#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y apache2
sudo apt-get install -y git

sudo systemctl enable apache2
sudo systemctl start apache2

git clone https://github.com/djeyapau/djeyapauweek3.git
mv djeyapauweek3/* /var/www/html/
