#!/bin/bash

echo "Enter the image id: "
read imgid

aws ec2 run-instances --image-id $imgid --key-name djeyapau --security-group-ids sg-2fb36456 --instance-type t2.micro --count 3 --client-token clitok --user-data file://installapp.sh --placement AvailabilityZone=us-west-2b

inst=$(aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,ClientToken]' | grep clitok | awk '{print $1}')

aws ec2 wait instance-running --instance-ids $inst

aws elb create-load-balancer --load-balancer-name djlb --listeners "Protocol=Http, LoadBalancerPort=80, InstanceProtocol=Http, InstancePort=80" --availability-zones us-west-2b --subnets subnet-subn --security-groups sg-2fb36456

aws elb register-instances-with-load-balancer --load-balancer-name djlb --instances $inst

aws autoscaling create-launch-confguration --launch-configuration-name djlc --image-id $imgid --key-name djeyapau --instance-type t2.micro --user-data file:/installapp.sh

aws autoscaling create-auto-scaling-group --auto-scaling-group-name djasg --launch-configuration djlc --availability-zone us-west-2b --max-size 5 --min-size 0 --desired-capacity 1

aws autoscaling attach-instances --instance-ids $inst --auto-scaling-group-name djasg

aws autoscaling attach-load-balancers --load-balancer-names djlb --auto-scaling-group-name djasg
