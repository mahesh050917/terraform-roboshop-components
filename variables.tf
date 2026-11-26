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

variable "components" {
  type = string
}

variable "health_check_port" {
   default = ""
}

variable "rule_priority" {
  type = number
}


variable "health_check_path" {
   default = "/health"
}