This module depends on infrastructure set up in the `deployment-common` repo, including the ECR repository that will host the container image for the resource provisioner lambda.

Once that has been set up, you need to push the container image to your ECR repository. This can be done by exporting the environment variables with AWS authentication information:
```
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

For convenience, also set a variable that contains the account ID for your AWS account:

```
export AWS_ACCOUNT_ID=
```

You should now be able to transfer the image from the public repo:

```
podman pull docker.io/bluebrain/hpc-resource-provisioner:latest
podman push bluebrain/hpc-resource-provisioner:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/hpc/resource-provisioner:latest
```

Now you can deploy the HPC or resource-provisioner module as normal.
