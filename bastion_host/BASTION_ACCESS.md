# Bastion Host Access Guide

This guide explains how to connect to a bastion host using AWS Systems Manager (SSM) for secure access to resources in private subnets. This method avoids exposing SSH ports directly.

## Prerequisites
- AWS CLI installed and configured.
- The `BastionUserAccess` permission set assigned to your AWS user.

## Step 1: Configure AWS Profile

Add the following profiles to your `~/.aws/config` file. These profiles configure the AWS CLI to use the correct SSO session, account ID, and role for accessing the staging and production environments.

```ini
[profile BastionUserAccess-staging]
sso_session = obi
sso_account_id = 992382665735
sso_role_name = BastionUserAccess
region = us-east-1
output = json

[profile BastionUserAccess-prod]
sso_session = obi
sso_account_id = 671250183987
sso_role_name = BastionUserAccess
region = us-east-1
output = json
```

## Step 2: Log in and Connect

The following commands will log you in, find the bastion instance, determine your username, and start the secure session.

### For STAGING Environment

First, log in:
```bash
aws sso login --profile BastionUserAccess-staging
```

Then, run this block to connect:
```bash
# Set the profile for the environment
export AWS_PROFILE="BastionUserAccess-staging"

# Get the bastion instance ID
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=*Bastion*" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text)

# Get your username from your AWS identity
USERNAME=$(aws sts get-caller-identity --query 'UserId' --output text | cut -d: -f2 | cut -d'@' -f1)

# Start the SSM session
echo "Connecting to instance $INSTANCE_ID as user $USERNAME..."
aws ssm start-session --target "$INSTANCE_ID" --document-name "SSM-UserMapping-$USERNAME"
```

### For PRODUCTION Environment

First, log in:
```bash
aws sso login --profile BastionUserAccess-prod
```

Then, run this block to connect:
```bash
# Set the profile for the environment
export AWS_PROFILE="BastionUserAccess-prod"

# Get the bastion instance ID
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=*Bastion*" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text)

# Get your username from your AWS identity
USERNAME=$(aws sts get-caller-identity --query 'UserId' --output text | cut -d: -f2 | cut -d'@' -f1)

# Start the SSM session
echo "Connecting to instance $INSTANCE_ID as user $USERNAME..."
aws ssm start-session --target "$INSTANCE_ID" --document-name "SSM-UserMapping-$USERNAME"
```

## Troubleshooting

- **`An error occurred (UnauthorizedOperation) when calling the DescribeInstances operation`**:
  - Your `BastionUserAccess` role may not have the required permissions.
  - Ensure you have logged in via `aws sso login` for the correct profile.

- **`Could not find a running Bastion instance`**:
  - The bastion host might be stopped or terminated. Contact an administrator.
  - You might be in the wrong AWS region. The profile specifies `us-east-1`.

- **`An error occurred (TargetNotConnected) when calling the StartSession operation`**:
  - The SSM agent on the bastion host may not be running. Contact an administrator.

- **`aws: command not found`**:
  - The AWS CLI is not installed or is not in your system's PATH.
