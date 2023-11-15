variable "ssm_parameter" {
  description = <<EOF
    [Required] A list of maps of SSM parameters to create. The map must contain the following keys:
    - name: The name of the parameter.
      - Recommended format: /<environment>/<service>/<parameter_name>
    - description: The description of the parameter.
    - type: The type of the parameter. Valid values are String, StringList, or SecureString.
      - Refer to https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_Parameter.html for more information.
    - value: The value of the parameter.
    - tier: The tier of the parameter. Valid values are Standard, Advanced, or IntelligentTiering.
      - Refer to https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-advanced-parameters.html for more information.
    - additional_tags: A map of additional tags to apply to the parameter.
  EOF
  type = list(object({
    name            = string
    description     = string
    type            = string
    value           = string
    tier            = optional(string)
    additional_tags = optional(map(string))
  }))

  validation {
    condition = alltrue([
      for parameter in var.ssm_parameter :
      can(regex("^/", parameter.name))
    ])
    error_message = "The name must start with a slash and use the recommended format: /<environment>/<service>/<parameter_name>."
  }

  validation {
    condition = alltrue([
      for parameter in var.ssm_parameter :
      can(regex("^(String|StringList|SecureString)$", parameter.type))
    ])
    error_message = "The type must be one of String, StringList, or SecureString."
  }

  validation {
    condition = alltrue([
      for parameter in var.ssm_parameter :
      parameter.tier == null ||
      can(regex("^(Standard|Advanced|IntelligentTiering)$", parameter.tier
      ))
    ])
    error_message = "The tier must be one of Standard, Advanced, or IntelligentTiering, or null/empty string."
  }
}

variable "create_kms_key" {
  description = "[OPTIONAL] If true, a KMS key will be created and used to encrypt the CloudWatch log group."
  type        = bool
  default     = false
}

variable "kms_key" {
  description = "[OPTIONAL] The ARN of the KMS key to use to encrypt the CloudWatch log group."
  type        = string
  default     = ""
}

variable "kms_key_extra_role_arns" {
  description = "[OPTIONAL] The ARNs of the IAM roles that should be able to use the KMS key."
  type        = list(string)
}