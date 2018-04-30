variable "public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "trusted_cidr" {
  description = "trusted cidr use by bastion"
  default     = "0.0.0.0/0"
}
