variable "name" {
  description = "the name of the ALB"
}

variable "internal" {
  description = "the type of the ALB"
  default = false
}

variable "subnets" {
  description = "subnets for ALB"
  type = list
}

variable "group_name" {
  description="The name of the security group"
}

variable "vpc_id" {
  description = "The ID o the destination VPC"
}

variable "tg_name" {
  description = "the name of the target group"
}

variable "tg_port" {
  description = "the port of the target"
}

variable "tg_protocol" {
  description = "the protocol to use on the target"
}