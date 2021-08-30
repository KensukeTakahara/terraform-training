variable "subnet_ids" {
  type = list(string)
}

variable "log_bucket_id" {
  type = string
}

variable "security_groups" {
  type = list(string)
}
