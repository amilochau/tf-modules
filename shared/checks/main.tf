resource "null_resource" "check_host" {
  lifecycle {
    precondition {
      condition = terraform.workspace == var.conventions.host_name
      error_message = "The current workspace is ${terraform.workspace}, but you used the conventions with host ${var.conventions.host_name}!"
    }
  }
}
