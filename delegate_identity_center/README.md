# Delegation of identity center

According to the AWS recommendations, identity center management should be delegated to a separate member account. From within that member account, you can setup the connection with an identity provider (entraid at the Open Brain Institute) and configure users/groups/permission sets and the associations of a group with a permission set with a certain AWS account.

Delegating the identity center with Terraform doesn't seem to work: that was done manually. Also the setup of SAML with EntraID and the SCIM provisioning of users from EntraID to AWS Identity Center was done manually.

The users, groups, permission sets and the assocations of groups with permission sets and aws accounts is done with terraform code from the aws-terraform-iam-identity-center repo, within the delegated member account. Due to AWS restrictions, that member account does not have the rights to create the associations in the root/management account => we'll need to setup some IAM role and policy that can be used from that member account, to execute those associations within the root/management account. That's configured in this module.
