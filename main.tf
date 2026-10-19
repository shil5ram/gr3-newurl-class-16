terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # --- REMOTE STATE LOCKING & STORAGE CONFIGURATION ---
#   backend "s3" {
#     bucket       = "sctp-tfstate-ce13"            # Shared sandbox backend bucket
#     key          = "group3-url-shortener.tfstate" # REPLACE 'group3' with your group name
#     region       = "us-east-1"                    # Region where your state file resides
#     encrypt      = true                           # Automatically encrypts your state at rest
#     use_lockfile = true                           # Shared state locking mechanism table
#   }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  domain_name = "${var.group_number}-url-shortener.sctp-sandbox.com"
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  group_number = var.group_number
}

module "waf" {
  source       = "./modules/waf"
  group_number = var.group_number
  my_ip_cidr   = var.my_ip_cidr
}

module "lambda" {
  source       = "./modules/lambda"
  group_number = var.group_number
  table_name   = module.dynamodb.table_name
  table_arn    = module.dynamodb.table_arn
  domain_name  = local.domain_name
}

module "api-gateway" {
  source              = "./modules/api-gateway"
  group_number        = var.group_number
  domain_name         = local.domain_name
  create_invoke_arn   = module.lambda.create_invoke_arn
  retrieve_invoke_arn = module.lambda.retrieve_invoke_arn
  create_name         = module.lambda.create_name
  retrieve_name       = module.lambda.retrieve_name
  web_acl_arn         = module.waf.web_acl_arn
}
