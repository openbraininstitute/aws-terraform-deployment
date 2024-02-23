# The domain that we use for the SBO POC: shapes-registry.org.
# The production domains: openbrainplatform.org and .com
# Migrated to the deployments-common repo.

# Use one of the exports:
# POC domain.
# TODO: remove once migration to production domain is done.
# * data.terraform_remote_state.common.outputs.domain_zone_id
# * data.terraform_remote_state.common.outputs.domain_arn

# Production domain.
# * data.terraform_remote_state.common.outputs.primary_domain
# * data.terraform_remote_state.common.outputs.primary_domain_zone_id
# * data.terraform_remote_state.common.outputs.primary_domain_arn
