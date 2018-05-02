variable "public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "trusted_cidr" {
  description = "trusted cidr use by bastion"
  default     = "0.0.0.0/0"
}

variable "agent_asg_name" {
  description = "titusagent ASG name"
   default =   "titusagent"
}