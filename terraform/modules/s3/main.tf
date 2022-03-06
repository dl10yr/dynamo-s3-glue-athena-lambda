resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "${var.project_name}-${var.env}-lambda"
}

resource "aws_s3_bucket" "table_export" {
  bucket = "${var.project_name}-${var.env}-table-export"
}

resource "aws_s3_bucket" "query_result" {
  bucket = "${var.project_name}-${var.env}-query-result"
}