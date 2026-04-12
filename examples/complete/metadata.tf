locals {
  metadata = {
    aws_region     = "us-east-2"
    environment    = "Laboratory"
    public_domain  = "example.internal"
    private_domain = "example"

    key = {
      company = "demo"
      region  = "use2"
      env     = "lab"
      layer   = "security"
    }
  }

  common_name = join("-", [
    local.metadata.key.company,
    local.metadata.key.env
  ])
}
