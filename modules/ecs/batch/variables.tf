variable "execution_role_arn" {
  type = string
}

variable "event_role_arn" {
  type = string
}

variable "ecs_cluster_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}
