variable "default_tags" {
  default = {
    SBO_Billing = "nexus"
  }
}

variable "openscience" {
  default = {
    SBO_Billing = "nexus-openscience"
  }
}

#########
## OBP ##
#########
provider "aws" {
  default_tags {
    tags = var.default_tags
  }
  region = var.aws_region
}

provider "aws" {
  alias = "nexus_blazegraph_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "blazegraph"
      }
    )
  }
  region = var.aws_region
}

provider "aws" {
  alias = "nexus_delta_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "delta"
      }
    )
  }
  region = var.aws_region
}

provider "aws" {
  alias = "nexus_fusion_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "fusion"
      }
    )
  }
  region = var.aws_region
}

provider "aws" {
  alias = "nexus_iam_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "iam"
      }
    )
  }
  region = var.aws_region
}

provider "aws" {
  alias = "nexus_networking_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "networking"
      }
    )
  }
  region = var.aws_region
}

provider "aws" {
  alias = "nexus_postgres_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "postgres"
      }
    )
  }
  region = var.aws_region
}

provider "aws" {
  alias = "nexus_ship_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "ship"
      }
    )
  }
  region = var.aws_region
}

provider "aws" {
  alias = "nexus_dashboard_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "dashboard"
      }
    )
  }
  region = var.aws_region
}

#################
## Openscience ##
#################

provider "aws" {
  alias = "nexus_openscience_postgres_tags"
  default_tags {
    tags = merge(
      var.openscience,
      {
        Nexus = "postgres"
      }
    )
  }
  region = var.aws_region
}

provider "aws" {
  alias = "nexus_openscience_blazegraph_tags"
  default_tags {
    tags = merge(
      var.openscience,
      {
        Nexus = "blazegraph"
      }
    )
  }
  region = var.aws_region
}
