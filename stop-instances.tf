resource "aws_key_pair" "my_key" {
  key_name   = "my-key"
  public_key = "ssh-rsa ..."
}

resource "aws_instance" "my_instance" {
  ami           = "ami-0eb48a19a8d81e20b"           // Ubuntu 18.04 LTS
  instance_type = "t3.micro"
  key_name      = "${aws_key_pair.my_key.key_name}"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_cloudwatch_event_rule" "stop_my_instance" {
  name                = "StopMyInstance"
  description         = "Stop my instance nightly"
  schedule_expression = "cron(0 19 * * ? *)"
}

data "aws_iam_policy_document" "stop_my_instance" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:RebootInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances",
    ]

    resources = ["${aws_instance.my_instance.arn}"]
  }
}

data "aws_iam_policy_document" "stop_my_instance_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "stop_my_instance" {
  name               = "StopMyInstance"
  assume_role_policy = "${data.aws_iam_policy_document.stop_my__instance_assume_role_policy.json}"
}

resource "aws_iam_role_policy" "stop_my_instance" {
  name   = "stop_my_instance_policy"
  role   = "${aws_iam_role.stop_my_instance.id}"
  policy = "${data.aws_iam_policy_document.stop_my_instance.json}"
}

resource "aws_cloudwatch_event_target" "stop_my_instance" {
  target_id = "StopInstance"
  arn       = "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:target/stop-instance"
  rule      = "${aws_cloudwatch_event_rule.stop_my_instance.name}"
  role_arn  = "${aws_iam_role.stop_my_instance.arn}"
  input     = "\"${aws_instance.my_instance.id}\""
}
