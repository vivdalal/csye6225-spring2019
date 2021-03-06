#!/bin/bash
port22CidrBlock="0.0.0.0/0"

#set -e

f () {
    errcode=$? # save the exit code as the first thing done in the trap function
    echo "error $errcode"
    echo "the command executing at the time of the error was"
    echo "$BASH_COMMAND"
    echo "on line ${BASH_LINENO[0]}"
    echo "Exiting the script."
    exit $errcode
}

trap f ERR

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
read -p "Enter VPC name and VPC Cidr block: " vpcName vpcCidrBlock
if [[ -z "$vpcName" ]] || [[ -z "$vpcCidrBlock" ]]; then
  echo "Kindly provide vpcName and VPC Cidr block"
  echo "Exiting..."
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  exit 1
else
  echo "Creating VPC.."
  aws_response=$(aws ec2 create-vpc --cidr-block $vpcCidrBlock --output json)
  echo "VPC Created"
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  vpcId=$(echo -e "$aws_response" |  /usr/bin/jq '.Vpc.VpcId' | tr -d '"')
  aws ec2 create-tags --resources "$vpcId" --tags Key=Name,Value="$vpcName"
fi

echo "Creating Route Table for VPC"
route_table_response=$(aws ec2 create-route-table --vpc-id "$vpcId" --output json)
routeTableId=$(echo -e "$route_table_response" |  /usr/bin/jq '.RouteTable.RouteTableId' | tr -d '"')
echo "Route Table created"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

region=()
regionlist=()
echo "please select region from below: "
for region in `aws ec2 describe-availability-zones --output text | cut -f5`
do
     region+=($region)
     echo -e $region
done
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

for i in {1..3}
do
  read -p "Please enter availability zone from above, subnetcidrblock and subnet name: " availabilityZone subnetcidrblock subnetName
  if [[ -z "$availabilityZone" ]] || [[ -z "$subnetcidrblock" ]] || [[ -z "$subnetName" ]]; then
    echo "availability zone or subnetcidrblock or subnet name cannot be blank"
    echo "Exiting..."
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    exit 1
  elif [[ ! " ${region[@]} " =~ " ${availabilityZone} " ]]; then
    echo "please eneter a valid availability zone"
    echo "Exiting..."
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    exit 1
  elif [[ " ${regionlist[@]} " =~ " ${availabilityZone} " ]]; then
    echo "subnet with this availability zone already exists, please enter unique availability zone"
    echo "Exiting..."
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    exit 1
  else
  regionlist+=($availabilityZone)
  subnet_response=$(aws ec2 create-subnet --vpc-id "$vpcId" --cidr-block $subnetcidrblock --availability-zone=$availabilityZone)
  subnetId=$(echo -e "$subnet_response" |  /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
  associate_response=$(aws ec2 associate-route-table --subnet-id "$subnetId" --route-table-id "$routeTableId")
  aws ec2 create-tags --resources "$subnetId" --tags Key=Name,Value="$subnetName"
  echo "Subnet with name : $subnetName created successfully. SubnetID : $subnetId"
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
fi
done

echo "Creating Internet Gateway"
gateway_response=$(aws ec2 create-internet-gateway --output json)
gatewayId=$(echo -e "$gateway_response" |  /usr/bin/jq '.InternetGateway.InternetGatewayId' | tr -d '"')
echo "Internet Gateway Created"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

echo "Attaching Internet Gateway to VPC"
attach_response=$(aws ec2 attach-internet-gateway --internet-gateway-id "$gatewayId"  --vpc-id "$vpcId")
echo "Gateway Attached"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

read -p "Please enter destination cidr block for adding route to the internet gateway: " destinationCidrBlock
if [[ -z "$destinationCidrBlock" ]]; then
  echo "Kindly provide destination cidr block"
  echo "Exiting"
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  exit 1
else
  route_response=$(aws ec2 create-route --route-table-id "$routeTableId" --destination-cidr-block "$destinationCidrBlock" --gateway-id "$gatewayId")
  echo "Route added to the internet gateway"
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
fi

echo "Updating the Security Groups"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
groupdetails=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" --output json)
groupid=$(echo -e "$groupdetails" |  /usr/bin/jq  '.SecurityGroups[0].GroupId' | tr -d '"')
userIdGroupPairs=$(echo -e "$groupdetails" |  /usr/bin/jq  '.SecurityGroups[0].IpPermissions[0].UserIdGroupPairs[0].GroupId' | tr -d '"')
cidrEgress=$(echo -e "$groupdetails" |  /usr/bin/jq  '.SecurityGroups[0].IpPermissionsEgress[0].IpRanges[0].CidrIp' | tr -d '"')
aws ec2 revoke-security-group-ingress --group-id "$groupid" --protocol all --source-group "$userIdGroupPairs"
aws ec2 revoke-security-group-egress --group-id "$groupid" --protocol all --port all --cidr "$cidrEgress"
security_response=$(aws ec2 authorize-security-group-ingress --group-id "$groupid" --protocol tcp --port 22 --cidr "$port22CidrBlock")
security_response=$(aws ec2 authorize-security-group-ingress --group-id "$groupid" --protocol tcp --port 80 --cidr "$port22CidrBlock")
echo "Security Group created and rules have been updated"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

echo "Script execution completed successfully!"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
