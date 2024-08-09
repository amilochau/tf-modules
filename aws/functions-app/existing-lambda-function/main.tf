terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.59.0, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.9.2, < 2.0.0"
}

module "conventions" {
  source  = "../../../shared/conventions"
  context = var.context
}

# ===== EXISTING LAMBDA FUNCTION =====

data "aws_lambda_function" "lambda_function" {
  function_name = var.function_name

  provider = aws.workloads
}

# ===== API GATEWAY TRIGGER =====

resource "aws_lambda_permission" "apigateway_permission" {
  count         = length(var.triggers_settings.api_gateway_routes) > 0 ? 1 : 0   # @todo what if multiple routes?
  statement_id  = "AllowExecutionFromAPIGateway-${var.context.application_name}" # @todo Improve that with a dedicated naming convention
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.triggers_settings.api_gateway_routes[0].api_execution_arn}/*/*" # Allow invocation from any stage, any method, any resource path @todo restrict that?

  provider = aws.workloads
}

module "trigger_api_gateway_routes" {
  for_each = { for k, v in var.triggers_settings.api_gateway_routes : k => v }
  source   = "../lambda-function/trigger-api-gateway-route"

  function_settings = {
    invoke_arn = data.aws_lambda_function.lambda_function.invoke_arn
  }
  api_gateway_settings = each.value

  providers = {
    aws.workloads = aws.workloads
  }
}
