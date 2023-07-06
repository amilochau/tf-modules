resource "aws_budgets_budget" "budget" {
  name         = var.budget_settings.name
  budget_type  = "COST"
  limit_amount = var.budget_settings.limit_amount_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = { for k, v in var.budget_settings.notifications : k => v }

    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = v.threshould_percent
      threshold_type             = "PERCENTAGE"
      notification_type          = v.forecast ? "FORECASTED" : "ACTUAL"
      subscriber_email_addresses = v.email_addresses
    }
  }
}
