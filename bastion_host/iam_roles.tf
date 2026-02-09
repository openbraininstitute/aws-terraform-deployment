

# Define user groups and their permissions
locals {
  user_groups = {
    obi_users = {
      users = [
        { username = "bilal.meddah", email = "bilal.meddah@openbraininstitute.org", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKIVViUnQg9sW+JfY9/A113WXzMCzwQNdA02wORg2ocC bilal.meddah@openbraininstitute.org" },
        { username = "boris.bergsma", email = "boris.bergsma@openbraininstitute.org", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK1R/kDtZfS+8VC6+s2ZZxSypYS9Tlv6yGhGJaok64q0 boris.bergsma@openbraininstitute.org" },
        { username = "eleftherios.zisis", email = "eleftherios.zisis@openbraininstitute.org", public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1at36VDXWXddTNr0mhC2BUOztxUiSbDj1Bz/GRvLlid1D71MP+4e/RMv8553L7B2ovGymcJtWM7vfrP728lMr8F9zXU599qmdN+VcP+1xvpu5LPKUGopwKHDXbiZAGuKVqk3xRNmTpa54/wVXZsv5Pakyiu1lnqQkLaVFBcLjDZG98fN5O4vJ3nP8wnc3UVVrNg57mAErgHmnFe6K+IBRor/lZ27ffiDylzrwuFdKoQ91+LIOwQkrz49vKgvnvpy4QNtM7zWGzs/kQh2417LOCA/SkIyZl8i5M8ca663E6jeQekP6N+BxJkFyHaQzseQn/ptA/U/mLDG8E3SR/SbHfz28KMPA3Nv5kcC2Lh9AaWO4PFmmBbP5MS8WAQ02bKhI3dvskCm9HoZhpsh5SvMW9YhoFumuTOTpDXLq+4j9UI2niaiyxIuaZ+RmhJLEHiAnMLeg6bjpYG4Hbon99+fANF6DloxEqDQRl4j3+KZZzuY2FIL3U/D6SluamhqPpiyMgBLcZaeGqbhTTPPAeppBIJ78j4rq01cvQ+MTBTZL2l1GD8ZvbKkuCC2nxrz+xni2+VTO7VmjH59tks/21lRvsHqJi+OXC8atrw/uyU9wwkIbKsWwgt/FRXKtpz1dGVVuA4evPQcsnuuapfMUbcnWh4gp0B64NrVnww5JXZDVIw== eleftherios.zisis@openbraininstitute.org" },
        { username = "georges.khazen", email = "georges.khazen@openbraininstitute.org", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHLQLFpw99J4HtO+5V33q0sEr0IA4uTOvTTVdrUCPfPG georges.khazen@gmail.com" },
        { username = "gianluca.ficarelli", email = "gianluca.ficarelli@openbraininstitute.org", public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTQQu/jmTIhy7MjfoOlW6pqgjKpUa4r86UKlME7Tu0/l46xcmvnu64SvE99rLNUolNXdbv7PcnW/yzZpQery4ZCUtAzHLpPZQomu5v3AGa60JGXHRqtKu6ogv83VLgbsoEOPW50+WeBxJJYdrHq6kwc4AwFHlG1L8OsAj/b41HH530nAH7ytFcd8Z5JbUeXbvvT4Eouu+BUuSxvdq5Heq4G4OoYTLc9k+Eby4rjzTv1y5cn6nEmkX/fxhEs6ac+QIyyx1DyUD4LuSRvnpmUrSDcpVtHu61vJzTktVqbylU7J5GcBV5RDoAoOm/WnS3thNbWa3Y//x57OVgUCYd9JLM83zLbanaVPGwIoO77uWfmarKOnmLC7ycdr1B9ZPtZog0HyOh7qT7zXe4PCos3BVEUkQbOfXtXpU9pfJ8ce6LG6T+CUdkc8BHBlxVitsT2m+0kQr9LbilBJcw1sWyHMv5N984q9TQfz3IuX1sMtnVMEVe45TNT6M7goBJqdJsaatiunN7B19EVw1mtvQ58wOhHuA9GBIFWbQ5KJb1vK/JXsyjeE1CCa2oKoIAJOJgxwPnmvjGBnuIiP61b+fRo8UVfwXW+KdD1drgoC4y2D8NfdfvPip/atFnPKciWL9NK6Ur1CXNHilrDeKVTG4T2Pk1/iE0FdCTblmvoCO7No92VQ== gianluca.ficarelli@epfl.ch" },
        { username = "jan.krepl", email = "jan.krepl@openbraininstitute.org", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIECHHO560E7kkuapW3gP9Rzb+XkXnOKYK+0scqkbPHLp krepl@Jans-MacBook-Air.local" },
        { username = "jean-denis.courcol", email = "jean-denis.courcol@openbraininstitute.org", public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7ODbkDNLlwCDdhQLQLR7Gz6wVj3k+gU8Hzz6MMHxauwA/lW35KnWjxFplSFgwNmwc1SCfxbwQQiiN3c4EIO9FOYtsjefa9jaeTwUIiOhI48AAf6VXPNVOpugi+zH+emdMEHyIeCEG+aV96gEcugXkAdkOz6U6kBoujqTNmh5vlCFBhzEJ2xOCynCdlc0iqpoASVjNcS6VDNi6V4/TLVvE7rg/py/nnzDM0/AfQLMUn+noTDIfQrp1/B8GgedxCuYveOcS+cPvwJD2YkV8HYfBfqo8R/cDl4qYt3+1aY6cIDDVhDUniaG55fPZqNHm6G2RS5rRcpnT20pja9uPLIkxZm6io3rbQNFM1N3ATROtea9olpZcmgpSbcRvoh+Jua5to1YKDYOqTX61jCobVqSc0tYeV1k02wz3Yc86asOtglEukw9KJVaCI4sTDi7/1L9pS2dDU3WekXvf3idfI8uk25qbG3iL60bAC2HIVskeGxe0i76BqhtAlUSVk8tjwzKDQHMIJRWDH4UoR1MYnmJmBlfBixPJ3563u+K+Gqtj7Tyvvb0r5jbmpYMn6vvq/HhesieTy0aEeRp6qyqVMrHuVhIzr6wLKPLqdi4/EkuPGQgSAziHfEb0ZAXU+d0hryTR8AWiABQJymi5MKKZMRwJYIm0HYuixock/9FEeqeUew== courcol@courcol.ch" },
        { username = "juanjose.garcia", email = "juanjose.garcia@openbraininstitute.org", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzDi+u9H5BDwytC7NQDl6rSk/2Kbjf7Xh+YKjBxJI4t juanjose.garcia@Juans-MacBook-Pro.local" },
        { username = "mgevaert", email = "mgevaert@openbraininstitute.org", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCRTRSpJMLRRk0GuIcQ/OU5fGwgX0YhIMsy/sSgdzQc gevaert@theend" },
        { username = "nicolas.frank", email = "nicolas.frank@openbraininstitute.org", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJgSbMMZ1KDAuxUBxI04PqBoU6v4eoU3B6sjh0iTx864 aws" },
        { username = "pavlo.getta", email = "pavlo.getta@openbraininstitute.org", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHxrb0uKrJ0XqWA7lFLSNjk9OpfuB34q1wucUrhVOZAD pavlo.getta@openbraininstitute.org" },
      ]
      sudo_access = false
    }
    obi_administrators = {
      users = [
        { username = "daniel.fernandez", email = "daniel.fernandez@openbraininstitute.org", public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDnwCEkde+9uNQJ+sUPJwuCGbCQM1NFa5T0uPZNbQFTe1cw3XhW8X+HZg9em5xdX6NrT+R3gHTMvpqhLepmZzcWNpautY7qGG833i/gKO2VrTWf/Vd0aRefvc9ssWChWKWxnJu0IGnOJF7gSA27MMWvFHjIoYzPG0UVmfE+Nr1OYLMjpYEsxqj+bby44xD7ii7/hVJXp1reuRjOiSK+AosO1GNIkXcw7CQJy1gQ9VAc3qpKwv5uqBTlvKG8olL42U0Ndy61slyQrbJm3GVFIQFd4aIpYjEGlY+B1jhY+wvf8RxxjCqpJ8bz+yG+/QPzGEZeaDNYsOTxWIJRVSm9voLf danielfr@aur" },
        { username = "dries.verachtert", email = "dries.verachtert@openbraininstitute.org", public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCw84Bv2npIvI5l9F8KeHPbdxPhykNduYetKMzeFT6BlEN7GKeDsgP5hHjf54aYugYovEgPO6fVf9L+NVHh8NaXgOSnhXjI7r4Iz4hDkOIxHdDHk0VHXZ3aaKA3XhZteJtKXfez1PMFon/AOXSEZuou/kpyFYZdsGKpX1V6RcF8f3Xd1HmIDrFQ4i136RJZzWMgjZAdFEqLdQRk1uiN1MvsHOnCAyMBvgid7gYvmgJIJNLFlh6yQlketZDEnQuHsPO+q43GeakWQ4CF7nfJyds1PD8jjsI/Nhk8ZWDj4A5v1ULVdNqYMcVslC87PdhsuPEw+RA8zAquEq7TGZjmJqzPE9OEq0iD+sj8qq7ziPStp+JNHJdDaSeO3g08SeQiklFvvcQv5rNkh+uNKeln2lXPOgrNV8oajpYsomNKif/ORz1t9tUKbsIiWXeNnJyJrsDZlkll8xEJtbNJY2PDL47KdAdADEZZjOvNAo3L2jWDmA/swRBnZRX9yYaJ7zxmFuFpw4/KFpUhXH5kbckZ+BfjENuRdm/PUDtyyeYICpL6AFaGzMF91b2CGftfHI4Nq7D2Xf1yQcEwP4ZHymDwlAu+H247WGprYD71bCbKYDHGzIDgG8f4jL2PdbwuNZ0fIP42K334IfFRpfK0fhJ8kSkr0xT4Sdg8NeNHba6Vcg+uiQ== Dries Verachtert - mac" },
        { username = "erik.heeren", email = "erik.heeren@openbraininstitute.org", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICCwlGHR/vz8esSOTMtXT0qnO7zg+kjPJYicxjyryO3h heeren@bbd-fsczyl3" },
      ]
      sudo_access = true
    }
  }

  # Flatten the user list
  all_users = flatten([
    for group, config in local.user_groups : [
      for user in config.users : {
        username = user.username
        email    = user.email
        group    = group
        sudo     = config.sudo_access
      }
    ]
  ])
}

# Create IAM role for EC2 instances
resource "aws_iam_role" "ssm_instance_role" {

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "SSM-Instance-Role"
  }
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_instance_role.name
}

# Attach policy for S3 session logging
resource "aws_iam_role_policy" "session_logging_policy" {
  name = "session-logging-policy"
  role = aws_iam_role.ssm_instance_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:PutObjectAcl",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = [
          "${aws_s3_bucket.session_logs.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetEncryptionConfiguration"
        ]
        Resource = [
          "${aws_s3_bucket.session_logs.arn}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.session_logs.arn}",
          "${aws_cloudwatch_log_group.session_logs.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "kms_policy" {
  name = "kms-policy"
  role = aws_iam_role.ssm_instance_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.cloudwatch_logs.arn
      }
    ]
  })
}
