
provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Owner             = "david.arnone@softrams.com"
      provisioning_tool = "terraform"
      Purpose           = "poc - testing separation of eks and cluster foundation."
    }
  }
}
