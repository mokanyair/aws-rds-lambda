variable "subnet_ids" {
  type = list(string)
}

variable "security_group" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "secret_arn" {
  type = string
}

variable "db_instance_id" {
  type = string
}