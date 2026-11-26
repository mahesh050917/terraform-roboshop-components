variable "env" {
   default = "dev"
}

variable "project" {
    default = "roboshop"
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "app_version" {
  default = "v3"
}

variable "component" {
  default = ""
}

variable "health_check_port" {
   default = ""
}

variable "rule_priority" {
  default = ""
}