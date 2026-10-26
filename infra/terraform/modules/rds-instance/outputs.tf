output "identifier" {
  description = "Identificador da instância RDS."
  value       = aws_db_instance.this.identifier
}

output "address" {
  description = "Host da instância."
  value       = aws_db_instance.this.address
}

output "endpoint" {
  description = "Endpoint (host:port) da instância."
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "Database inicial do serviço."
  value       = aws_db_instance.this.db_name
}

output "jdbc_url" {
  description = "URL JDBC do database do serviço nesta instância."
  value       = "jdbc:postgresql://${aws_db_instance.this.address}:5432/${aws_db_instance.this.db_name}"
}

output "security_group_id" {
  description = "Security group da instância."
  value       = aws_security_group.this.id
}
