import {
  to = aws_default_security_group.default
  id = local.vpc_default_sg_id
}

import {
  to = module.hpc.module.vpc.aws_default_security_group.hpc_default
  id = module.hpc.pcluster_vpc_default_sg_id
}
