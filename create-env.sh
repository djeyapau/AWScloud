#!/bin/bash

if [ "$1" != "" ]; then
count1=1
else
count1=0
fi

if [ "$2" != "" ]; then
count2=1
else
count2=0
fi

if [ "$3" != "" ]; then
count3=1
else
count3=0
fi

if [ "$4" != "" ]; then
count4=1
else
count4=0
fi

if [ "$5" != "" ]; then
count5=1
else
count5=0
fi

count=$(($count1+$count2+$count3+$count4+$count5))

if [ "$count" -ne 5 ]; then
if [ "$count" -lt 5 ]; then
echo "\nLess than that of expectecd parameters\n"
fi
if [ "$count" -gt 5 ]; then
echo "\nMore than that of expectecd parameters\n"
fi
sleep 2
exit
fi
if [ "$count" -eq 5 ]; then
echo "\nAll positional parameters aboard! Lets start!\n"

echo "\nWelcome to Dharshini's first load balancer\n"

#input client token
echo "Enter a name for the group of instances (client token): "
echo "(Hint: Do not repeat any whole or part of an already used client token)"
read ct
echo "\n"

#run 3 instances
aws ec2 run-instances --image-id $1 --key-name $2 --security-group-ids $3 --instance-type t2.micro --count $5 --client-token $ct --user-data file://installapp.sh --placement AvailabilityZone=us-west-2b

#store the instances IDs into a variable
inst=`aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,ClientToken]' | grep $ct | awk '{print $1}'`

#wait till the instances run
aws ec2 wait instance-running --instance-ids $inst

#create load balancer
aws elb create-load-balancer --load-balancer-name djlb --listeners "Protocol=Http, LoadBalancerPort=80, InstanceProtocol=Http, InstancePort=80" --availability-zones us-west-2b --security-groups $3

#register the instances with the load balancer
aws elb register-instances-with-load-balancer --load-balancer-name djlb --instances $inst

#create launch configuration
aws autoscaling create-launch-configuration --launch-configuration-name $4 --image-id $1 --key-name $2 --instance-type t2.micro --user-data file:/installapp.sh

#create auto scaling group
aws autoscaling create-auto-scaling-group --auto-scaling-group-name djasg --launch-configuration $4 --availability-zone us-west-2b --max-size 5 --min-size 0 --desired-capacity 1

#attach instances to auto scaling group
aws autoscaling attach-instances --instance-ids $inst --auto-scaling-group-name djasg

#attach load balancer to auto scaling group
aws autoscaling attach-load-balancers --load-balancer-names djlb --auto-scaling-group-name djasg

aws autoscaling update-auto-scaling-group --auto-scaling-group-name djasg --launch-configuration-name $4 --min-size 2

echo "The script completed"

fi
