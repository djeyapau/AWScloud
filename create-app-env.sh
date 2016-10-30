#!/bin/bash

aws rds create-db-instance --engine mysql --db-name dev --db-instance-identifier dj-application --db-instance-class db.t2.micro --master-username controller --master-user-password Hor7crux --allocated-storage 5 --availability-zone us-west-2b

aws rds wait db-instance-available --db-instance-identifier dj-application

echo "The db instance is available now"
