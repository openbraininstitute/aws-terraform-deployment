aws_region     = "us-east-1"
aws_account_id = "671250183987"

vpc_id = "vpc-08aa04757a326969b"

dockerhub_access_iam_policy_arn = "arn:aws:iam::671250183987:policy/dockerhub-credentials-access-policy"
dockerhub_credentials_arn       = "arn:aws:secretsmanager:us-east-1:671250183987:secret:dockerhub-bbpbuildbot-EhUqqE"

domain_zone_id                = "Z08554442LEJ4EBB4CAIQ"
nat_gateway_id                = "nat-0a1f630f60bfcf279"
private_alb_dns_name          = "internal-sbo-poc-private-alb-1398645643.us-east-1.elb.amazonaws.com"
private_alb_listener_9999_arn = "arn:aws:elasticloadbalancing:us-east-1:671250183987:listener/app/sbo-poc-private-alb/9218a6246c00752c/dc7a6022650c8898"

aws_lb_alb_dns_name           = "sbo-poc-alb-1920595049.us-east-1.elb.amazonaws.com"
aws_lb_listener_sbo_https_arn = "arn:aws:elasticloadbalancing:us-east-1:671250183987:listener/app/sbo-poc-alb/f5dfcd670d2b881c/ac6c42d364b0efba"
