
### Gathering VPC IDs
export DefaultVpcId=$(aws ec2 describe-vpcs --query "Vpcs[].VpcId" --output json | jq -r '.[0]')
export GravitonVpcId=$(aws ec2 describe-vpcs --query "Vpcs[].VpcId" --output json | jq -r '.[1]')
echo $DefaultVpcId
echo $GravitonVpcId

### Route Table VPC IDs
export DefaultRouteTableID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${DefaultVpcId}" --query 'RouteTables[?Associations[0].Main == `true`]' --output json | jq -r '.[0].RouteTableId')
export GravitonRouteTableID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${GravitonVpcId}" --query 'RouteTables[?Associations[0].Main == `true`]'  --output json| jq -r '.[0].RouteTableId')
echo $DefaultRouteTableID
echo $GravitonRouteTableID

### VPC CIDRs
export DefaultRouteCidr=$(aws ec2 describe-vpcs --query "Vpcs[].CidrBlock" --output json | jq -r '.[0]')
export GravitonRouteCidr=$(aws ec2 describe-vpcs --query "Vpcs[].CidrBlock" --output json | jq -r '.[1]')
echo $DefaultRouteCidr
echo $GravitonRouteCidr

### Create the VPC peering and accept the request
export VpcPeeringId=$(aws ec2 create-vpc-peering-connection --vpc-id "$DefaultVpcId" --peer-vpc-id "$GravitonVpcId" --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id "$VpcPeeringId"

#### Graviton VPC CIDR / Source VPC route table config
aws ec2 create-route --route-table-id "$DefaultRouteTableID" --destination-cidr-block "$GravitonRouteCidr" --vpc-peering-connection-id "$VpcPeeringId"
aws ec2 create-route --route-table-id "$GravitonRouteTableID" --destination-cidr-block "$DefaultRouteCidr" --vpc-peering-connection-id "$VpcPeeringId"

#### Add  routes to Graviton Private Subnets
export GravitonPrivate1RouteTableID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${GravitonVpcId}" --query 'RouteTables[?Tags[3].Value == `GravitonID-base/BaseVPC/PrivateSubnet1`]'  --output json| jq -r '.[0].RouteTableId')
export GravitonPrivate2RouteTableID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${GravitonVpcId}" --query 'RouteTables[?Tags[3].Value == `GravitonID-base/BaseVPC/PrivateSubnet2`]'  --output json| jq -r '.[0].RouteTableId')
aws ec2 create-route --route-table-id "$GravitonPrivate1RouteTableID" --destination-cidr-block "$DefaultRouteCidr" --vpc-peering-connection-id "$VpcPeeringId"
aws ec2 create-route --route-table-id "$GravitonPrivate2RouteTableID" --destination-cidr-block "$DefaultRouteCidr" --vpc-peering-connection-id "$VpcPeeringId"
