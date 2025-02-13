data "aws_ssoadmin_instances" "iam_identity_center" {}

resource "aws_organizations_account" "account" {
  name      = var.account_name
  email     = var.account_email
  parent_id = var.account_parent_id
  role_name = "administrator-access"

  lifecycle {
    ignore_changes = [
      role_name
    ]
  }
}

resource "aws_ssoadmin_account_assignment" "account_assignment" {
  for_each = var.account_iam_assignments

  instance_arn       = tolist(data.aws_ssoadmin_instances.iam_identity_center.arns)[0]
  permission_set_arn = each.value.permission_set_arn

  principal_id   = each.value.principal_id
  principal_type = each.value.principal_type

  target_id   = aws_organizations_account.account.id
  target_type = "AWS_ACCOUNT"
}

resource "aws_cloudfront_origin_request_policy" "cloudfront_origin_request_policy_defaultapi" {
  name = "DefaultForApi"
  comment = "Policy to forward standard parameters in viewer requests ('Authorization' header, no cookie, all query strings)"

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Authorization", "Content-Type"]
    }
  }

  cookies_config {
    cookie_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_response_headers_policy" "cloudfront_response_headers_policy_defaultapi" {
  name = "DefaultForApi"
  comment = "Allows localhost for COST requests, including preflight requests, and adds security headers"

  cors_config {
    access_control_allow_credentials = true
    origin_override = true

    access_control_allow_headers {
      items = ["Authorization", "Content-Type"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD", "PUT", "POST", "PATCH", "DELETE", "OPTIONS"]
    }
    access_control_allow_origins {
      items = ["http://localhost:3000"]
    }
    access_control_expose_headers {
      items = ["*"]
    }
  }
  
  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      override = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override = true
    }
    content_type_options {
      override = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override = true
    }
    frame_options {
      frame_option = "SAMEORIGIN"
      override = true
    }
  }
}
