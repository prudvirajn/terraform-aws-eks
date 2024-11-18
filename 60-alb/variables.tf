variable "project_name" {
  default = "expense"
}

variable "environment" {
  default = "dev"
}

variable "common_tags" {
  default = {
    project     = "expense"
    Terraform   = "true"
    environment = "dev"
  }
}

variable "ingress_alb_tags" {
  default = {
    component = "app-alb"
  }
}

variable "zone_name" {
  default = "prudviraj.online"
}