resource "aws_glue_catalog_database" "users_glue_database" {
  name = "${var.project_name}-${var.env}-glue-database"
}