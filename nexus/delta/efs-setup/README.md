# Delta EFS

When the Delta module is instantiated, a blank EFS resource is created. In order to start Delta for the first time, some files need to be created manually.

To access the EFS we mount it to the SSH bastion. This is done via a CS managed puppet script. See [this MR](https://bbpgitlab.epfl.ch/cs/cloud/aws/puppet-bolt-configuration/-/merge_requests/38) as an example.

In order to mount it like this, the only prerequisite is the existance of the EFS (upon the instantiation of the Delta module), as well as the existence of a CNAME record for EFS.

This record can simply be created as follows:

```terraform
resource "aws_route53_record" "nexus_delta_efs" {
  zone_id = var.domain_zone_id
  name    = "nexus-delta-efs.shapes-registry.org"
  type    = "CNAME"
  ttl     = 60
  records = [module.nexus_delta.efs_delta_dns_name]
}
```

where the `var.domain_zone_id` is the id of the zone for the shapes-registry.org in this case; and `module.nexus_delta.efs_delta_dns_name` points to the DNS name of the EFS that was created and that is to be mounted.

Once the record exists and the puppet script has been created, you can access

```shell
ssh ssh.shapes-registry.org
```

and find the EFS mounted at the location specified in the puppet script.

From this point, you can populate the mount point by executing the steps that are described in the `delta-efs-setup.sh` file in this folder.