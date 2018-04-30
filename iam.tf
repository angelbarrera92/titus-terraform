data "aws_caller_identity" "current" {}

# titusmasterInstanceProfile
resource "aws_iam_role_policy" "titusmasterInstanceProfile" {
  name = "titusmasterInstanceProfile"
  role = "${aws_iam_role.titusmasterInstanceProfile.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "titusmasterInstanceProfile" {
  name = "titusmasterInstanceProfile"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# titusappwiths3InstanceProfile
resource "aws_iam_role_policy" "titusappwiths3InstanceProfile" {
  name = "titusappwiths3InstanceProfile"
  role = "${aws_iam_role.titusappwiths3InstanceProfile.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "titusappwiths3InstanceProfile" {
  name = "titusappwiths3InstanceProfile"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/titusmasterInstanceProfile"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# titusappnos3InstanceProfile
resource "aws_iam_role_policy" "titusappnos3InstanceProfile" {
  name = "titusappnos3InstanceProfile"
  role = "${aws_iam_role.titusappnos3InstanceProfile.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "titusappnos3InstanceProfile" {
  name = "titusappnos3InstanceProfile"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/titusmasterInstanceProfile"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
