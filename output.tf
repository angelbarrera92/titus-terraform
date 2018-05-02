output "bastion_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "gateway_ip" {
  value = "${aws_instance.gateway.private_ip}"
}

output "master_ip" {
  value = "${aws_instance.master.private_ip}"
}

output "prereqs_ip" {
  value = "${aws_instance.prereqs.private_ip}"
}

output "default_role_arn" {
  value = "${aws_iam_role.titusappwiths3InstanceProfile.arn}"
}

output "default_sg_arn" {
  value = "${aws_security_group.titusapp.id}"
}

output "agent_asg_name" {
  value = "${aws_autoscaling_group.titusagent.name}"
}
