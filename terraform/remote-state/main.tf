provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Purpose           = "poc - testing separation of eks and cluster foundation"
      provisioning_tool = "terraform"
      Owner             = "david.arnone@softrams."
    }
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "4i-init-582830503829-terraform-state"
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name                        = "4i-terraform-state-init-lock"
  read_capacity               = 1
  write_capacity              = 1
  hash_key                    = "LockID"
  deletion_protection_enabled = true


  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "RequireEncryption",
   "Statement": [
    {
      "Sid": "RequireEncryptedTransport",
      "Effect": "Deny",
      "Action": ["s3:*"],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.terraform_state.bucket}/*"],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      },
      "Principal": "*"
    },
    {
      "Sid": "RequireEncryptedStorage",
      "Effect": "Deny",
      "Action": ["s3:PutObject"],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.terraform_state.bucket}/*"],
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      },
      "Principal": "*"
    }
  ]
}
EOF
}