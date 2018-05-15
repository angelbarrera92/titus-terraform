variable "public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "trusted_cidr" {
  description = "trusted cidr use by bastion"
  default     = "0.0.0.0/0"
}

variable "agent_asg_name" {
  description = "titusagent ASG name"
  default     = "titusagent"
}

variable "s3_log_bucket_name" {
  description = "Titus S3 Bucket Log"
  default     = "titus-log-bucket-terraform-example"
}
