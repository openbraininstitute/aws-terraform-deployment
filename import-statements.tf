import {
  id = "arn:aws:iam::671250183987:policy/dockerhub-credentials-access-policy"
  to = module.dockerhub_secret.aws_iam_policy.dockerhub_access
}
