
echo "\nWelcome to Dharshini's first load balancer\n"

#input image id
echo "Enter the image id: "
read imgid
echo "\n"

#input client token
echo "Enter a name for the group of instances (client token): "
echo "(Hint: Do not repeat any whole or part of an already used client token)"
read ct
echo "\n"

#input key name
echo "Enter the key name: "
read keyname
echo "\n"

#input security group id
echo "Enter the security group id: "
read secgp
echo "\n"

#run 3 instances
aws ec2 run-instances --image-id $imgid --key-name $keyname --security-group-ids $secgp --instance-type t2.micro --count 3 --client-token $ct --user-data file://installapp.sh --placement AvailabilityZone=us-west-2b

#store the instances IDs into a variable
inst=$(aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,ClientToken]' | grep $ct | awk '{print $1}')

#wait till the instances run
aws ec2 wait instance-running --instance-ids $inst

#create load balancer
aws elb create-load-balancer --load-balancer-name djlb --listeners "Protocol=Http, LoadBalancerPort=80, InstanceProtocol=Http, InstancePort=80" --availability-zones us-west-2b --security-groups $secgp

#register the instances with the load balancer
aws elb register-instances-with-load-balancer --load-balancer-name djlb --instances $inst

#create launch configuration
aws autoscaling create-launch-configuration --launch-configuration-name djlc --image-id $imgid --key-name $keyname --instance-type t2.micro --user-data file:/installapp.sh

#create auto scaling group
aws autoscaling create-auto-scaling-group --auto-scaling-group-name djasg --launch-configuration djlc --availability-zone us-west-2b --max-size 5 --min-size 0 --desired-capacity 1

#attach instances to auto scaling group
aws autoscaling attach-instances --instance-ids $inst --auto-scaling-group-name djasg

#attach load balancer to auto scaling group
aws autoscaling attach-load-balancers --load-balancer-names djlb --auto-scaling-group-name djasg

aws autoscaling update-auto-scaling-group --auto-scaling-group-name djasg --launch-configuration-name djlc --min-size 2

echo "The script completed"
