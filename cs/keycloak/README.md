# Keycloak

## Accessing the Admin Console

The Keycloak admin console is exposed on a dedicated hostname and restricted at the ALB level to traffic originating from the bastion host's private IP.

| Environment | Admin hostname                                       | AWS profile  |
|-------------|------------------------------------------------------|--------------|
| Staging     | `keycloak-admin.staging.cell-a.openbraininstitute.org` | `staging`    |
| Production  | `keycloak-admin.cell-a.openbraininstitute.org`         | `production` |

To connect from your laptop:

### 1. Add a local hosts entry

```bash
# Staging
echo '127.0.0.1 keycloak-admin.staging.cell-a.openbraininstitute.org' | sudo tee -a /etc/hosts

# Production
echo '127.0.0.1 keycloak-admin.cell-a.openbraininstitute.org' | sudo tee -a /etc/hosts
```

This only needs to be done once per environment.

### 2. Set your environment

```bash
# Staging
export AWS_PROFILE=staging
export KEYCLOAK_ADMIN_HOST=keycloak-admin.staging.cell-a.openbraininstitute.org

# Production
export AWS_PROFILE=production
export KEYCLOAK_ADMIN_HOST=keycloak-admin.cell-a.openbraininstitute.org
```

### 3. Look up the bastion instance ID

```bash
BASTION_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=*Bastion*" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)
```

### 4. Open an SSM tunnel through the bastion

```bash
sudo -E aws ssm start-session \
  --target "$BASTION_INSTANCE_ID" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["'"$KEYCLOAK_ADMIN_HOST"'"],"portNumber":["443"],"localPortNumber":["443"]}'
```

`sudo -E` preserves the environment variables. `sudo` is required because port 443 is a privileged port on macOS/Linux.

### 5. Open the admin console

Navigate to:

```
https://$KEYCLOAK_ADMIN_HOST/auth/
```
