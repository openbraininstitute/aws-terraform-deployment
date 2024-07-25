# Sandbox

## Usage

Assumptions:
1. The nexus_postgresqul_password already exists in the password manager. This is the password that will be used for the db.
2. The nexus secret already exists in the password manager and contains the keys: "postgres_password", "remote_storage_password", "delegation_private_key". The "postgres_password" value is the same as in step 1.

In order to deploy a sandboxed Nexus:

1. Ensure that the `locals` defined in `sandbox.tf` are correct.
2. Define the following environment variables to be able to run the plan:
```shell
export TF_VAR_nise_dockerhub_password=$NISE_DOCKER_PASSWORD # from 1password secret called "Dockerhub"
export EC_API_KEY=$SANDBOX_EC_API_KEY # from 1password secret "ElasticCloud Sandbox API Key"
```
2. Via the terminal, go to the `sandbox` folder and run `terraform plan`.
3. Run `terraform apply`.

Currently we still get 2 DNS validation errors but these can be ignored for now.

In order to connect, you can go to the load balancer settings and find the name of the public load balancer. You can use its DNS name to query delta as follows:

```
curl --location '$LB_DNS_NAME/v1/version' \
--header 'Host: sbo-nexus-delta.shapes-registry.org'
```