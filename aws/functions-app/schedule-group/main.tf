module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

resource "aws_scheduler_schedule_group" "schedule_group" {
  name = module.conventions.aws_naming_conventions.eventbridge_schedule_group_name
}
