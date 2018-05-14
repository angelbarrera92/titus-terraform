resource "aws_security_group" "titusbastion" {
  name        = "titusbastion"
  description = "titusbastion"
  vpc_id      = "${aws_vpc.titus.id}"
}

resource "aws_security_group_rule" "bastion_egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.titusbastion.id}"
}

resource "aws_security_group_rule" "bastion_ssh_ip" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${var.trusted_cidr}"]

  security_group_id = "${aws_security_group.titusbastion.id}"
}

resource "aws_security_group_rule" "bastion_icmp" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.titusbastion.id}"
}

resource "aws_security_group" "titusapp" {
  name        = "titusapp"
  description = "titusapp"
  vpc_id      = "${aws_vpc.titus.id}"
}

resource "aws_security_group_rule" "titusapp_egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.titusapp.id}"
}

resource "aws_security_group_rule" "titusapp_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.titusbastion.id}"

  security_group_id = "${aws_security_group.titusapp.id}"
}

resource "aws_security_group_rule" "titusapp_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.titusbastion.id}"

  security_group_id = "${aws_security_group.titusapp.id}"
}

resource "aws_security_group" "titusmaster-mainvpc" {
  name        = "titusmaster-mainvpc"
  description = "titusmaster-mainvpc"
  vpc_id      = "${aws_vpc.titus.id}"
}

resource "aws_security_group_rule" "titus_master-mainvpc_egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.titusmaster-mainvpc.id}"
}

resource "aws_security_group_rule" "titus_master-mainvpc_tcp" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.titusmaster-mainvpc.id}"

  security_group_id = "${aws_security_group.titusmaster-mainvpc.id}"
}

resource "aws_security_group_rule" "titus_master-mainvpc_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.titusbastion.id}"

  security_group_id = "${aws_security_group.titusmaster-mainvpc.id}"
}

resource "aws_security_group_rule" "titus_master-mainvpc_icmp" {
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "icmp"
  source_security_group_id = "${aws_security_group.titusmaster-mainvpc.id}"

  security_group_id = "${aws_security_group.titusmaster-mainvpc.id}"
}
