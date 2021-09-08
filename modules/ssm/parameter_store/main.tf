resource "aws_ssm_parameter" "db_username" {
  name        = "/db/username"
  value       = "root"
  type        = "String"
  description = "データベースのユーザ名"
  overwrite   = true
}

# パスワードはAWSコンソール上から手動で入れる
# resource "aws_ssm_parameter" "db_password" {
#   name        = "/db/password"
#   value       = "uninitialized"
#   type        = "SecureString"
#   description = "データベースのパスワード"

#   lifecycle {
#     ignore_changes = [value]
#   }
# }
