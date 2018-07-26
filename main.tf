#

provider "aws" {
  region = "us-east-2"
}
output "s3_bucket_arn" {
  value = "${aws_s3_bucket.terraform_remote_state.arn}"
}

resource "aws_s3_bucket" "terraform_remote_state"{
  bucket = "terraform-uandr-state-lcgillies"
  versioning {
    enabled = true
  }
  lifecycle {
    prevent_destroy = true
  }
}

terraform {
  backend "s3" {
    bucket  = "terraform-uandr-state-lcgillies"
    region  = "us-east-2"
    key     = "terraform.tfstate"
    encrypt = true
  }
}
