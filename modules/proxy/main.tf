resource "aws_db_proxy" "proxy" {
  name                   = "rds-proxy"
  engine_family          = "MYSQL"
  role_arn               = var.role_arn
  vpc_subnet_ids         = var.subnet_ids
  vpc_security_group_ids = [var.security_group]

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = var.secret_arn
  }
}

resource "aws_db_proxy_default_target_group" "default" {
  db_proxy_name = aws_db_proxy.proxy.name
}

resource "aws_db_proxy_target" "target" {
  db_proxy_name          = aws_db_proxy.proxy.name
  target_group_name      = aws_db_proxy_default_target_group.default.name
  db_instance_identifier = var.db_instance_id
}