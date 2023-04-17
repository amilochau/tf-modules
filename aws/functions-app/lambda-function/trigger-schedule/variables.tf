variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
    temporary        = bool
  })
}

variable "function_settings" {
  description = "Settings to use for the schedule"
  type = object({
    function_key = string
    function_arn = string
  })
}

variable "schedule_settings" {
  description = "Settings for the previously deployed EventBridge Schedule group"
  type = object({
    schedule_group_name = string
    schedules = list(object({
      description = string
      schedule_expression = string
    }))
  })
}
