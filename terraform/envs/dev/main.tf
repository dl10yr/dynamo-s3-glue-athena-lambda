locals {
  project_name = "dynamo-s3-glue-athena-lambda"
  env          = "dev"
  region       = "ap-northeast-1"
}

provider "aws" {
  region = local.region
}

terraform {
  backend "s3" {
    bucket = "dynamo-s3-glue-athena-lambda-tfstate"
    key    = "dynamo-s3-glue-athena-lambda-tfstate/dev.tfstate"
    region = "ap-northeast-1"
  }
}

module "dynamodb" {
  source       = "../../modules/dynamodb"
  project_name = local.project_name
  env          = local.env
}

module "glue" {
  source       = "../../modules/glue"
  project_name = local.project_name
  env          = local.env
}

module "iam" {
  source             = "../../modules/iam"
  project_name       = local.project_name
  env                = local.env
  dynamodb_table_arn = module.dynamodb.users_table_arn
  s3_bucket_arn      = module.s3.bucket_export_arn
}

module "s3" {
  source       = "../../modules/s3"
  project_name = local.project_name
  env          = local.env
}

module "ssm" {
  source                = "../../modules/ssm"
  project_name          = local.project_name
  env                   = local.env
  lambda_role_arn       = module.iam.lambda_role_arn
  glue_crawler_role_arn = module.iam.glue_crawler_role_arn
  users_table_arn       = module.dynamodb.users_table_arn
}
