resource "aws_iam_instance_profile" "ec2_for_ssm" {
  name = "ec2-for-ssm"
  role = var.iam_role_name
}

resource "aws_instance" "example_for_operation" {
  ami                  = "ami-0c3fd0f5d33134a76"
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_for_ssm.name
  subnet_id            = var.private_subnet_id
  user_data            = file("${path.module}/user_data.sh")
}

resource "aws_cloudwatch_log_group" "operation" {
  name              = "/operation"
  retention_in_days = 180
}

resource "aws_ssm_document" "session_manager_run_shell" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = <<EOF
  {
    "schemaVersion": "1.0",
    "description": "Document to hold regional settings for Session Manager.",
    "sessionType": "Standard_Stream",
    "inputs": {
      "s3BucketName": "${var.operation_bucket_id}",
      "cloudWatchLogGroupName": "${aws_cloudwatch_log_group.operation.name}"
    }
  }
  EOF
}
