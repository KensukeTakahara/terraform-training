output "iam_role_arn" {
  value = aws_iam_role.default
}

output "iam_role_name" {
  value = aws_iam_role.default.name
}
