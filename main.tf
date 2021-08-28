module "describe_regions_for_ec2" {
  source     = "./modules/iam_role"
  name       = "describe-region-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.allow_describe_regions.json
}
