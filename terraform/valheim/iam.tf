resource "aws_iam_role" "default" {
  name               = "${var.namespace}-${var.region}"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags

}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "default" {
  name   = var.namespace
  role   = aws_iam_role.default.name
  policy = data.aws_iam_policy_document.default.json
}

data "aws_iam_policy_document" "default" {

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:${var.region}:${data.aws_caller_identity.current.account_id}:accesspoint/${aws_s3_bucket.default.id}"]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:${var.region}:${data.aws_caller_identity.current.account_id}:accesspoint/${aws_s3_bucket.default.id}/object/*"]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:GetLogEvents",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutRetentionPolicy",
      "logs:PutMetricFilter",
      "logs:CreateLogGroup"
    ]
    resources = [aws_cloudwatch_log_group.default.arn]
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEC2RoleforSSM" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.default.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.default.name
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.default.name
}

resource "aws_iam_instance_profile" "default" {
  name = "${var.namespace}-${var.region}"
  role = aws_iam_role.default.name
}

#s3 accesspoint

data "aws_iam_policy_document" "ssm_s3_accesspoint" {

  statement {
    principals {
      type = "AWS"
      identifiers = [
        "*"
      ]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:${var.region}:${data.aws_caller_identity.current.account_id}:accesspoint/${aws_s3_bucket.default.id}",
      "arn:aws:s3:${var.region}:${data.aws_caller_identity.current.account_id}:accesspoint/${aws_s3_bucket.default.id}/object/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:AccessPointNetworkOrigin"
      values = [
        "VPC"
      ]
    }
  }
}