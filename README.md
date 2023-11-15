# Terraform AWS SSM Parameters

This terraform module creates SSM parameters in AWS.

## Usage

```hcl
module "ssm_parameters" {
  source = "git::https://github.com/hgeorge123/aws-ssm-parameter.git?ref=vX.X.X"

  create_kms_key          = true
  kms_key_extra_role_arns = "arn:aws:iam::123456789012:role/extra-role-arn"
  ssm_parameter = [
    {
      name        = "/myapp/dev/database/username"
      description = "The username for the database"
      type        = "SecureString"
      value       = var.database_username
    },
    {
      name        = "/myapp/dev/database/password"
      description = "The password for the database"
      type        = "SecureString"
      value       = var.database_password
    },
    {
      name        = "/myapp/vpc/dev/id"
      description = "The VPC ID"
      type        = "String"
      value       = module.vpc.vpc_id
    }
  ]
}
```
