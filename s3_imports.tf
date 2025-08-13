import {
  id = trimprefix(var.infrastructureassets_bucket, "s3://")
  to = module.hpc.module.s3.aws_s3_bucket.sboinfrastructureassets
}

import {
  id = trimprefix(var.infrastructureassets_bucket, "s3://")
  to = module.hpc.module.s3.aws_s3_bucket_policy.sboinfrastructureassets
}
