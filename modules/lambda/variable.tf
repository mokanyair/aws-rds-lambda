variable "subnet_ids" {
  type = list(string)
}

variable "security_group" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_pass" {
  type = string
}

variable "proxy_endpoint" {
  type = string
}