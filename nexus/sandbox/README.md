# Sandbox

## Usage

In order to deploy a sandboxed Nexus:

1. Ensure that the `locals` defined in `sandbox.tf` are correct.
    1. Create the nexus and psql secret manually. Populate the psql secret with a plaintext password, this will be the password used when creating the DB.
    2. Fill the nexus password with the same keys as in the `nexus_app` secret in production, and adapt the values.
    3. Define the `TF_VAR_nise_dockerhub_password` to be the password from the NISE Dockerhub credentials. This can be currently found in the NISE 1password.
2. Via the terminal, go to the `sandbox` folder and run `terraform plan`.
3. Run `terraform apply`.
4. Check on the sandbox Elasticsearch deployment on cloud.elastic.com (use the sandbox credentials from 1password to log in), and reset the password for the `elastic` user. Copy the new one into the nexus secret in Secret Manager.

Currently we still get 2 DNS validation errors but these can be ignored for now.

In the future we can replace step 4 by reading the secret from the ES deployment via terraform and put it into a secret that can be read by Delta.

In order to connect, you can go to the load balancer settings and find the name of the public load balancer. You can use its DNS name to query delta as follows:

```
curl --location '$LB_DNS_NAME/v1/version' \
--header 'Host: sbo-nexus-delta.shapes-registry.org'
```