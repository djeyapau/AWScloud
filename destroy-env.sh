#!/bin/bash

asg=`aws autoscaling describe-auto-scaling-groups --output json | grep AutoScalingGroupName | cut -f 4 -d "\""`

lc=`aws autoscaling describe-launch-configurations --output json | grep LaunchConfigurationName | cut -f 4 -d "\""`

for line in $asg; do
for line1 in $lc; do
	aws autoscaling update-auto-scaling-group --auto-scaling-group-name $line --launch-configuration-name $line1 --min-size 0 --desired-capacity 0
done
done

lb=`aws elb describe-load-balancers --output json | grep LoadBalancerName | cut -f 4 -d "\""`

for line2 in $asg; do
for line7 in $lb; do
aws autoscaling detach-load-balancers --load-balancer-names $line7 --auto-scaling-group-name $line2
done
done

echo "\n\nIGNORE THE ABOVE ERROR(S)"

for line3 in $asg; do
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $line3 --force-delete
done

for line4 in $lc; do
aws autoscaling delete-launch-configuration --launch-configuration-name $line4
done

for line5 in $lb; do
ins=`aws elb describe-load-balancers --load-balancer-name $line5 --output json | grep InstanceId | cut -f 4 -d "\""`
aws elb deregister-instances-from-load-balancer --load-balancer-name $line5 --instances $ins	
done

for line6 in $lb; do
aws elb delete-load-balancer-listeners --load-balancer-name $line6 --load-balancer-ports 80
done

for line8 in $lb; do
aws elb delete-load-balancer --load-balancer-name $line8
done

rins=`aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --output json | grep InstanceId | cut -f 4 -d "\""`

echo "\nEverything has been destroyed!!!"
