variable "region" {
  description = "Região da AWS"
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "Expected AWS account ID. Guards the provider against deploying to the wrong account. Empty = no restriction (local validation)."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID da VPC existente"
}

variable "subnet_ids" {
  description = "Lista de subnets privadas para o Aurora"
  type        = list(string)
}

variable "db_username" {
  description = "Usuário master do PostgreSQL RDS"

  validation {
    condition = !contains([
      "admin",
      "postgres",
      "root",
      "rdsadmin"
    ], lower(var.db_username))
    error_message = "DB_USERNAME usa um nome reservado pelo PostgreSQL RDS. Use, por exemplo, dbadmin."
  }
}

variable "db_name" {
  description = "Nome do banco PostgreSQL por ambiente."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.db_name))
    error_message = "db_name deve conter apenas letras minúsculas, números e hífens, começando por uma letra."
  }
}

variable "db_password" {
  description = "Senha master do PostgreSQL RDS"
  sensitive   = true
}

variable "run_migrations" {
  description = "Controla se o Terraform deve executar os scripts DDL/DML via provisioner local-exec (use somente quando o runner tiver acesso à VPC)."
  type        = bool
  default     = true
}
