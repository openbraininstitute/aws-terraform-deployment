# Sandbox

## Usage

Assumptions:
1. The nexus_postgresql_password already exists in the password manager. This is the password that will be used for the db.
2. The nexus secret already exists in the password manager and contains the keys: "postgres_password", "remote_storage_password", "delegation_private_key". The "postgres_password" value is the same as in step 1.
3. The ElasticCloud API key for the sandbox ElasticCloud account is stored in the ec_api_key secret (search for "ElasticCloud Sandbox API Key" in 1password and see https://bbpteam.epfl.ch/project/spaces/display/NISE/Elastic+Cloud)
4. The NISE DockerHub password is stored in the nise_dockerhub_password secret (search for "NISE Dockerhub" in 1password).
5. The AWS profile you use to run the terraform commands has admin access (https://bbpteam.epfl.ch/project/spaces/display/NISE/Sandbox)

In order to deploy a sandboxed Nexus:

1. Ensure that the `locals` defined in `sandbox.tf` are correct.
2. Via the terminal, go to the `sandbox` folder and run `terraform plan`.
3. Run `terraform apply`.
4. To kill the deployment use `terraform destroy`. This will leave a clean slate for the next time without deleting the existing secrets in secret manager.

If instead you use aws-nuke, ensure that Secret Manager resource are not deleted using filter. If you do end up deleting the secrets, you will need to recreate manually the ones that are described in the "Assumptions" above.

Currently, we still get 2 DNS validation errors but these can be ignored for now.

In order to connect, you can go to the load balancer settings and find the name of the public load balancer. You can use its DNS name to query delta as follows:

```
curl --location '$LB_DNS_NAME/v1/version' \
--header 'Host: sbo-nexus-delta.shapes-registry.org'
```