# Nexus Storage Service
The storage service is run using ECS with EC2 (rather than Fargate as for the other containerised apps). Since EC2 is not managed by AWS we have to provide more config such as AMI, instance type and IAM roles.

With this we can mount the S3 bucket containing nexus data when the EC2 instance is launched (done in [init_storage_instance](./init_storage_instance.sh)). When ECS sees that there's an eligible EC2 instance, it starts a containerised task on this instance. This is able to read/write to S3 using the mount as a POSIX file system.

An auto-scaling group / capacity provider is used to launch instances once the terraform is applied.

TODO:
1. Add a load balancer and output the host for delta.
2. Switch production delta to point to this storage service and not the one on the parallel cluster.
