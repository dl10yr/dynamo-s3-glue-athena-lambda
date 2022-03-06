resource "aws_dynamodb_table" "users_table" {
  name         = "${var.project_name}-${var.env}-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}