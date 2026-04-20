output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "lambda_sg" {
  value = aws_security_group.lambda_sg.id
}

output "rds_sg" {
  value = aws_security_group.rds_sg.id
}