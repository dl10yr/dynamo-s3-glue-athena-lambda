resource "aws_ssm_parameter" "users_table_arn" {
  name = "/${var.project_name}/${var.env}/users-table-arn"
  type = "String"
  value = var.users_table_arn
}

resource "aws_ssm_parameter" "lambda_role_arn" {
  name = "/${var.project_name}/${var.env}/lambda-role-arn"
  type = "String"
  value = var.lambda_role_arn
}

resource "aws_ssm_parameter" "glue_crawler_role_arn" {
  name = "/${var.project_name}/${var.env}/glue-crawler-role-arn"
  type = "String"
  value = var.glue_crawler_role_arn
}

resource "aws_ssm_parameter" "s3_export_arn" {
  name = "/${var.project_name}/${var.env}/s3-export-arn"
  type = "String"
  value = "none" 
}