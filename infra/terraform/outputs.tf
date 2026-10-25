output "instance_identifiers" {
  description = "Identificador da instância RDS de cada serviço."
  value       = { for svc, m in module.service_db : svc => m.identifier }
}

output "instance_endpoints" {
  description = "Endpoint (host:port) da instância de cada serviço."
  value       = { for svc, m in module.service_db : svc => m.endpoint }
}

output "service_databases" {
  description = "Database inicial de cada serviço."
  value       = { for svc, m in module.service_db : svc => m.db_name }
}

# URL JDBC por serviço, cada uma apontando para a SUA instância dedicada. É a
# base do secret DB_URL_<ENV> de cada microsserviço (um banco por serviço).
output "service_jdbc_urls" {
  description = "Mapa serviço -> URL JDBC da sua instância RDS dedicada."
  value       = { for svc, m in module.service_db : svc => m.jdbc_url }
  sensitive   = true
}

output "security_group_ids" {
  description = "Security group de cada instância."
  value       = { for svc, m in module.service_db : svc => m.security_group_id }
}
