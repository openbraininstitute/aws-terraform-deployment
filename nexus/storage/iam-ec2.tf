data "aws_iam_policy_document" "nexus_storage_ec2_instance_role_policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "nexus_storage_ec2_instance_role" {
  name               = "nexus_storage_ec2_instance_role"
  assume_role_policy = data.aws_iam_policy_document.nexus_storage_ec2_instance_role_policy_doc.json
  tags               = { SBO_Billing = "nexus_storage" }
}

resource "aws_iam_role_policy_attachment" "nexus_storage_ec2_instance_role_policy" {
  role       = aws_iam_role.nexus_storage_ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "nexus_storage_ec2_instance_role_s3_policy" {
  role       = aws_iam_role.nexus_storage_ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "nexus_storage_ec2_instance_role_profile" {
  name = "NexusStorage_EC2_InstanceRoleProfile"
  role = aws_iam_role.nexus_storage_ec2_instance_role.name
  tags = { SBO_Billing = "nexus_storage" }
}
