
### Gathering VPC IDs
DefaultVpcId=$(aws ec2 describe-vpcs --query "Vpcs[].VpcId" --output json | jq -r '.[0]')
GravitonVpcId=$(aws ec2 describe-vpcs --query "Vpcs[].VpcId" --output json | jq -r '.[1]')
echo $DefaultVpcId
echo $GravitonVpcId

### Route Table VPC IDs
DefaultRouteTableID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${DefaultVpcId}" --query 'RouteTables[?Associations[0].Main == `true`]' --output json | jq -r '.[0].RouteTableId')
GravitonRouteTableID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${GravitonVpcId}" --query 'RouteTables[?Associations[0].Main == `true`]'  --output json| jq -r '.[0].RouteTableId')
echo $DefaultRouteTableID
echo $GravitonRouteTableID

### VPC CIDRs
DefaultRouteCidr=$(aws ec2 describe-vpcs --query "Vpcs[].CidrBlock" --output json | jq -r '.[0]')
GravitonRouteCidr=$(aws ec2 describe-vpcs --query "Vpcs[].CidrBlock" --output json | jq -r '.[1]')
echo $DefaultRouteCidr
echo $GravitonRouteCidr

### Create the VPC peering and accept the request
VpcPeeringId=$(aws ec2 create-vpc-peering-connection --vpc-id "$DefaultVpcId" --peer-vpc-id "$GravitonVpcId" --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id "$VpcPeeringId"

#### Graviton VPC CIDR / Source VPC route table config
aws ec2 create-route --route-table-id "$DefaultRouteTableID" --destination-cidr-block "$GravitonRouteCidr" --vpc-peering-connection-id "$VpcPeeringId"
aws ec2 create-route --route-table-id "$GravitonRouteTableID" --destination-cidr-block "$DefaultRouteCidr" --vpc-peering-connection-id "$VpcPeeringId"

####

Rds5Sg=$(aws cloudformation describe-stacks --stack-name GravitonID-rds-5 --query "Stacks[0].Outputs[2].OutputValue" --output text)
#C9PrivateIp=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.privateIp')
aws ec2 authorize-security-group-ingress --group-id "$Rds5Sg" --protocol tcp --port 22 --cidr $DefaultRouteCidr

