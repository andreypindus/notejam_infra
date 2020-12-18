variable "cidr_block" {
  description = "Default VPC CIDR block"
}

variable "enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC. Defaults false."
}

variable "vpc_name" {
  description = "A name of the VPC"
}

variable "public_subnets" {
  description = "Cidr block of the public subnet"
  default     = []
}

variable "private_subnets" {
  description = "Cidr block of the private subnet"
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is false."
  default     = true
}

variable "public_subnet_names" {
  description = "Name of the subnet"
  default     = []
}

variable "private_subnet_names" {
  description = "Name of the subnet"
  default     = []
}

variable "internet_gateway_name" {
  description = "Name of the internet gateway"
}

variable "azs" {
  description = "A list of availability zones in the region"
  default     = []
}
