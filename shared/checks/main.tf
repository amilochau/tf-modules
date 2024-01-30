resource "null_resource" "check_host" {
  lifecycle {
    precondition {
      condition     = terraform.workspace == var.context.host_name
      error_message = "The current workspace is ${terraform.workspace}, but you used the context with host ${var.context.host_name}!"
    }
  }
}
