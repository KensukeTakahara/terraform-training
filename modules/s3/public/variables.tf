variable "bucket_name" {
  type = string
}

variable "origins" {
  type = list(string)
}

variable "methods" {
  type = list(string)
}

variable "headers" {
  type = list(string)
}
