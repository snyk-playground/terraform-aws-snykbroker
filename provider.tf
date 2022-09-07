# provider scope configuration
provider "aws" {
  default_tags {
    tags = var.default_tags
  }
}
