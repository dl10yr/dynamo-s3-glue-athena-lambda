output "bucket_export_arn" {
  value = aws_s3_bucket.table_export.arn
}
output "bucket_query_result_arn" {
  value = aws_s3_bucket.query_result.arn
}