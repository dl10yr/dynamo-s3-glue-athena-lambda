locals {
  lambda_role_name       = "${var.project_name}-${var.env}-lambda-iam-role"
  glue_crawler_role_name = "${var.project_name}-${var.env}-glue-iam-role"
}

// lambda
data "aws_iam_policy" "lambda_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy" "lambda_s3_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "aws_iam_policy" "lambda_ssm_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

data "aws_iam_policy" "lambda_glue_service_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

data "aws_iam_policy" "lambda_ahena_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}

data "aws_iam_policy" "lambda_invocation_dynamodb" {
  arn = "arn:aws:iam::aws:policy/AWSLambdaInvocation-DynamoDB"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "allow_dynamodb_access" {
  statement {
    actions = [
      "dynamodb:ExportTableToPointInTime"
    ]
    resources = ["${var.dynamodb_table_arn}*"]
  }
}

data "aws_iam_policy_document" "allow_iam_pass_role" {
  statement {
    actions = [
      "iam:Get*",
      "iam:List*",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
}


resource "aws_iam_role" "lambda_role" {
  name               = local.lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "allow_lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_basic_execution.arn
}

resource "aws_iam_role_policy_attachment" "allow_lambda_s3_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_s3_full_access.arn
}

resource "aws_iam_role_policy_attachment" "allow_lambda_ssm_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_ssm_full_access.arn
}

resource "aws_iam_role_policy_attachment" "allow_lambda_glue_service_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_glue_service_role.arn
}

resource "aws_iam_role_policy_attachment" "allow_lambda_ahena_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_ahena_full_access.arn
}

resource "aws_iam_role_policy_attachment" "allow_lambda_invocation_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_invocation_dynamodb.arn
}

resource "aws_iam_role_policy" "allow_iam_pass_role" {
  name   = "${local.lambda_role_name}-allow-iam-pass-role"
  role   = aws_iam_role.lambda_role.name
  policy = data.aws_iam_policy_document.allow_iam_pass_role.json
}

resource "aws_iam_role_policy" "allow_dynamodb_access" {
  name   = "${local.lambda_role_name}-dynamodb-access"
  role   = aws_iam_role.lambda_role.name
  policy = data.aws_iam_policy_document.allow_dynamodb_access.json
}


// glue
data "aws_iam_policy_document" "glue_crawler_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy" "glue_s3_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "aws_iam_policy" "glue_cloudwatch_full_access" {
  arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

data "aws_iam_policy" "glue_glue_service_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role" "glue_crawler_role" {
  name               = local.glue_crawler_role_name
  assume_role_policy = data.aws_iam_policy_document.glue_crawler_assume_role.json
}

resource "aws_iam_role_policy_attachment" "allow_glue_s3_full_access" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = data.aws_iam_policy.glue_s3_full_access.arn
}

resource "aws_iam_role_policy_attachment" "allow_glue_cloudwatch_full_access" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = data.aws_iam_policy.glue_cloudwatch_full_access.arn
}

resource "aws_iam_role_policy_attachment" "allow_glue_glue_service_role" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = data.aws_iam_policy.glue_glue_service_role.arn
}
