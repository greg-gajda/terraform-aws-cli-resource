variable "cmd" {
  description = "The command used to create the resource."
}

variable "destroy_cmd" {
  description = "The command used to destroy the resource."
}

variable "account_id" {
  description = "The account that holds the role to assume in. Will use providers account by default"
  default     = "0"
}

variable "role" {
  description = "The role to assume in order to run the cli command."
  default     = "0"
}

variable "dependency_ids" {
  description = "IDs or ARNs of any resources that are a dependency of the resource created by this module."
  type        = list(string)
  default     = []
}

data "aws_caller_identity" "id" {}

locals {
  account_id      = "${var.account_id == 0 ? data.aws_caller_identity.id.account_id : var.account_id}"
  assume_role_cmd = "source /tmp/assume_role.sh ${local.account_id} ${var.role}"
}

resource "null_resource" "assume_role" {
  triggers = {
    cmd = "echo ${base64decode("cm9sZV9zZXNzaW9uX25hbWU9YGNhdCAvcHJvYy9zeXMva2VybmVsL3JhbmRvbS91dWlkIDI+L2Rldi9udWxsIHx8IGRhdGUgfCBja3N1bSB8IGN1dCAtZCAiICIgLWYgMWAKYXdzX2NyZWRzPSQoYXdzIHN0cyBhc3N1bWUtcm9sZSAtLXJvbGUtYXJuIGFybjphd3M6aWFtOjokMTpyb2xlLyQyIC0tcm9sZS1zZXNzaW9uLW5hbWUgJHJvbGVfc2Vzc2lvbl9uYW1lIC0tZHVyYXRpb24tc2Vjb25kcyAzNjAwIC0tb3V0cHV0IGpzb24pCmlmIFsgIiQ/IiAtbmUgMCBdOyB0aGVuIGV4aXQgMTsgZmkKZXhwb3J0IEFXU19BQ0NFU1NfS0VZX0lEPSQoZWNobyAiJHthd3NfY3JlZHN9IiB8IGdyZXAgQWNjZXNzS2V5SWQgfCBhd2sgLUYnIicgJ3twcmludCAkNH0nICkKZXhwb3J0IEFXU19TRUNSRVRfQUNDRVNTX0tFWT0kKGVjaG8gIiR7YXdzX2NyZWRzfSIgfCBncmVwIFNlY3JldEFjY2Vzc0tleSB8IGF3ayAtRiciJyAne3ByaW50ICQ0fScgKQpleHBvcnQgQVdTX1NFU1NJT05fVE9LRU49JChlY2hvICIke2F3c19jcmVkc30iIHwgZ3JlcCBTZXNzaW9uVG9rZW4gfCBhd2sgLUYnIicgJ3twcmludCAkNH0nICkKZXhwb3J0IEFXU19TRUNVUklUWV9UT0tFTj0kKGVjaG8gIiR7YXdzX2NyZWRzfSIgfCBncmVwIFNlc3Npb25Ub2tlbiB8IGF3ayAtRiciJyAne3ByaW50ICQ0fScgKQplY2hvICJzZXNzaW9uICckcm9sZV9zZXNzaW9uX25hbWUnIHZhbGlkIGZvciA2MCBtaW51dGVzIg==")} > /tmp/assume_role.sh"
  }

  provisioner "local-exec" {
    when = "create"
    command = "/bin/bash -c '${self.triggers.cmd}'"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "/bin/bash -c '${self.triggers.cmd}'"
  }
}

resource "null_resource" "cli_resource" {
  triggers = {
    cmd_create = "${var.role == "0" ? "" : "${local.assume_role_cmd} && "}${var.cmd}"
    cmd_destroy = "${var.role == "0" ? "" : "${local.assume_role_cmd} && "}${var.destroy_cmd}"
  }

  provisioner "local-exec" {
    when    = "create"
    command = "/bin/bash -c '${self.triggers.cmd_create}'"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "/bin/bash -c '${self.triggers.cmd_destroy}'"
  }

  # By depending on the null_resource, the cli resource effectively depends on the existance
  # of the resources identified by the ids provided via the dependency_ids list variable.
  depends_on = ["null_resource.dependencies"]
}

resource "null_resource" "dependencies" {
  triggers {
    dependencies = "${join(",", var.dependency_ids)}"
  }
}

output "id" {
  description = "The ID of the null_resource used to provison the resource via cli. Useful for creating dependencies between cli resources"
  value       = "${null_resource.cli_resource.id}"
}