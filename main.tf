module "vpc" {
  source = "./modules/vpc"
}

module "secrets" {
  source      = "./modules/secrets"
  db_username = var.db_username
  db_password = var.db_password
}

module "rds" {
  source         = "./modules/rds"
  subnet_ids     = module.vpc.private_subnets
  security_group = module.vpc.rds_sg
  db_username    = var.db_username
  db_password    = var.db_password
}

module "iam" {
  source     = "./modules/iam"
  secret_arn = module.secrets.secret_arn
}

module "proxy" {
  source         = "./modules/proxy"
  subnet_ids     = module.vpc.private_subnets
  security_group = module.vpc.rds_sg
  role_arn       = module.iam.proxy_role_arn
  secret_arn     = module.secrets.secret_arn
  db_instance_id = module.rds.db_id
}

module "lambda" {
  source         = "./modules/lambda"
  subnet_ids     = module.vpc.private_subnets
  security_group = module.vpc.lambda_sg
  db_name        = var.db_name
  db_user        = var.db_username
  db_pass        = var.db_password
  proxy_endpoint = module.proxy.proxy_endpoint
}

module "sqs" {
  source     = "./modules/sqs"
  lambda_arn = module.lambda.lambda_arn
}