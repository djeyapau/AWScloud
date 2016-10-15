#!/bin/bash

count=0

for var in "$@"
do
count=$(($count+1))
done

if [ "$count" -lt 5 ]; then
echo "\nLess than that of expectecd parameters\n"

if [ -z "$1" ]; then
echo "Please specify Image ID as the first positional parameter"
fi
if [ -z "$2" ]; then
echo "Please specify key-name as the second positional parameter"
fi
if [ -z "$3" ]; then
echo "Please specify security-group as the third positional parameter"
fi
if [ -z "$4" ]; then
echo "Please specify launch-configuration as the fourth positional parameter"
fi
if [ -z "$5" ]; then
echo "Please specify count as the fifth positional parameter"
fi

exit
fi

if [ "$count" -gt 5 ]; then
echo "\nMore than that of expectecd parameters\n"
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
