module "kms" {
  source          = "git@github.com:softrams-iac/terraform-aws-kms-legacy.git//?ref=v5.0.0"
  name            = "${local.project}-${local.environment}"
  deletion_window = "10"
  key_rotation    = true
  kms_policy = [
    {
      effect    = "Allow"
      actions   = ["kms:*"]
      resources = ["*"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${local.aws_account_number}:root"]
        }
      ]
    }
  ]
  tags = null
}