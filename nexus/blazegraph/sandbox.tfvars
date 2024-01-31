aws_region               = "us-east-1"
vpc_id                   = "vpc-04bb3a574ca8ed8ea"
vpc_cidr_block           = "10.0.0.0/16"
subnet_id                = "subnet-0b7efbe81901493e7"
subnet_security_group_id = "sg-07cb47bad77fe7b72"

# Set to the LB DNS name and listener in sandbox, outputted by module.common
private_blazegraph_hostname   = "internal-sbo-poc-private-alb-1638372866.us-east-1.elb.amazonaws.com"
private_alb_listener_9999_arn = "arn:aws:elasticloadbalancing:us-east-1:058264116529:listener/app/sbo-poc-private-alb/d9ef06e707f7d27e/170615062bf52ead"

# Not used in sandbox
domain_zone_id = ""
