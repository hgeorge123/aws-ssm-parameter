# Get Account ID:
data "aws_caller_identity" "current" {}

locals {
  # Create a list of all secure string parameters:
  secure_string_parameter = [for parameter in var.ssm_parameter : parameter if parameter.type == "SecureString"]
}

# Create a CMK for encrypting CloudWatch log groups:
resource "aws_kms_key" "ssm_parameter" {
  for_each = {
    for parameter in local.secure_string_parameter : parameter.name => parameter
    if var.create_kms_key
  }

  description             = "CMK to encrypt SSM parameter - ${each.value.name}"
  deletion_window_in_days = 30    # Hardcoded to the maximum allowed value.
  multi_region            = false # Not required for CloudWatch log group encryption.
  enable_key_rotation     = true  # Hardcoded to enforce key rotation.

  tags = { Name = each.value.name }
}

# Allow the ECS agent to use the CMK:
resource "aws_kms_key_policy" "ssm_parameter" {
  for_each = {
    for parameter in local.secure_string_parameter : parameter.name => parameter
    if var.create_kms_key
  }

  key_id = aws_kms_key.ssm_parameter[each.key].id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Sid" : "Enable IAM User Permissions",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : concat(["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"], var.kms_key_extra_role_arns)
      },
      "Action" : "kms:*",
      "Resource" : aws_kms_key.ssm_parameter[each.key].arn
      },
      {
        "Sid" : "Allow SSM to use the key",
        "Effect" : "Allow",
        "Principal" : { "Service" : "ssm.amazonaws.com" },
        "Action" : [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        "Resource" : aws_kms_key.ssm_parameter[each.key].arn
    }]
  })
}

# Create an alias for the CMK:
resource "aws_kms_alias" "ssm_parameter" {
  for_each = {
    for parameter in local.secure_string_parameter : parameter.name => parameter
    if var.create_kms_key
  }

  name          = lower("alias/${each.value.name}")
  target_key_id = aws_kms_key.ssm_parameter[each.key].arn
}

locals {
  key_id = {
    for parameter in var.ssm_parameter : parameter.name => parameter.type == "SecureString" && var.create_kms_key ? aws_kms_key.ssm_parameter[parameter.name].arn : var.kms_key
  }
}

# Create the SSM parameters:
resource "aws_ssm_parameter" "this" {
  for_each = { for parameter in var.ssm_parameter : parameter.name => parameter }

  name        = each.value.name
  description = each.value.description
  type        = each.value.type
  key_id      = each.value.type == "SecureString" ? local.key_id[each.key] : null
  value       = each.value.value
  tier        = try(each.value.tier, null)

  tags = merge(
    each.value.additional_tags,
    {
      "Name" = each.value.name
    },
  )
}