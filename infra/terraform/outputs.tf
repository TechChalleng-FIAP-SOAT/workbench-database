output "aurora_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "aurora_port" {
  value = 5432
}

output "aurora_database" {
  value = var.db_name
}

output "aurora_jdbc_url" {
  value     = "jdbc:postgresql://${aws_db_instance.postgres.address}:5432/${var.db_name}"
  sensitive = true
}