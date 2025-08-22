resource "aws_cognito_user_pool" "main" {
  name                = var.pool_name
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection = var.deletion_protection ? "ACTIVE" : "INACTIVE"
  
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your verification code is {####}."
    email_subject        = "Your verification code from FHIR"
    sms_message          = "Your verification code is {####}."
  }

  schema {
    name                = "address"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "birthdate"
    attribute_data_type = "String"
    mutable             = true
    required            = false
    string_attribute_constraints {
      min_length = "10"
      max_length = "10"
    }
  }
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }
  schema {
    name                = "family_name"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "gender"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "given_name"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "locale"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "middle_name"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "name"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "nickname"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "picture"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "preferred_username"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "profile"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "updated_at"
    attribute_data_type = "Number"
    mutable             = true
    required            = false
    number_attribute_constraints {
      min_value = "0"
    }
  }
  schema {
    name                = "website"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "zoneinfo"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  schema {
    name                = "TenantId"
    attribute_data_type = "Number"
    mutable             = true
    required            = false
    number_attribute_constraints {
      min_value = "0"
    }
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "main" {
  name         = var.app_client_name
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false
  allowed_oauth_flows_user_pool_client = true
  
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid", "phone"]
  callback_urls = var.app_callback_urls

  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  prevent_user_existence_errors = "LEGACY"

  read_attributes = [
    "address", "birthdate", "custom:TenantId", "email", "email_verified",
    "family_name", "gender", "given_name", "locale", "middle_name", "name",
    "nickname", "phone_number", "phone_number_verified", "picture",
    "preferred_username", "profile", "updated_at", "website", "zoneinfo"
  ]
  write_attributes = [
    "address", "birthdate", "custom:TenantId", "email", "family_name",
    "gender", "given_name", "locale", "middle_name", "name", "nickname",
    "phone_number", "picture", "preferred_username", "profile",
    "updated_at", "website", "zoneinfo"
  ]
}

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "blockly_identity"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = "cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
    server_side_token_check = false
  }
}