terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.62, < 5.0.0"
    }
  }

  required_version = ">= 1.3.0"
}

module "environment" {
  source      = "../../shared/environment"
  conventions = var.conventions
}

module "conventions" {
  source      = "../../shared/conventions"
  conventions = var.conventions
}

resource "aws_cognito_user_pool" "cognito_user_pool" {
  name                     = module.conventions.aws_naming_conventions.cognito_userpool_name
  auto_verified_attributes = ["email"]
  deletion_protection      = module.environment.is_production ? "ACTIVE" : "INACTIVE"
  mfa_configuration        = "OPTIONAL"
  username_attributes      = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
    #invite_message_template {
    #email_subject = "Hello {username}, you have been invited to participate to our new experiences. Here is your temporary password: {####}. Thanks!"
    #email_message = "You have been invited!"
    #}
  }

  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = false
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT" # @todo use a real SES account here
    #configuration_set = ""
    #source_arn = ""
    #from_email_address = ""
    #reply_to_email_address = ""
  }

  password_policy {
    minimum_length                   = 6
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }

  schema {
    name                     = "email"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = true
    developer_only_attribute = false
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                     = "name"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = true
    developer_only_attribute = false
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  software_token_mfa_configuration {
    enabled = true
  }

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  username_configuration {
    case_sensitive = false
  }

  verification_message_template {
    #email_subject = "Confirm your account!"
    #email_message = "Hi {username}, here is your code: {####}."
  }

  lifecycle {
    prevent_destroy = true
  }
}
