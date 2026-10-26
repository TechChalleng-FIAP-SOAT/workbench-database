variable "service" {
  description = "Nome do serviço dono desta instância (ex.: os_service)."
  type        = string
}

variable "identifier" {
  description = "Identificador da instância RDS (ex.: workshop-os-service-main)."
  type        = string
}

variable "db_name" {
  description = "Nome do database inicial criado na instância (ex.: os_service)."
  type        = string
}

variable "db_username" {
  description = "Usuário master do PostgreSQL desta instância."
  type        = string

  validation {
    condition = !contains([
      "admin",
      "postgres",
      "root",
      "rdsadmin"
    ], lower(var.db_username))
    error_message = "db_username usa um nome reservado pelo PostgreSQL RDS. Use, por exemplo, dbadmin."
  }
}

variable "db_password" {
  description = "Senha master do PostgreSQL desta instância."
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC onde a instância vive."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets privadas para o subnet group da instância."
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group dos nós do EKS; recebe acesso à 5432. Null = sem regra do EKS."
  type        = string
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "CIDRs extras liberados na 5432 (ex.: runner de migração)."
  type        = list(string)
  default     = []
}

variable "instance_class" {
  description = "Classe da instância RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Armazenamento em GB."
  type        = number
  default     = 20
}

variable "publicly_accessible" {
  description = "Expõe a instância publicamente. Mantenha false."
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Criptografia em repouso (KMS). Mantenha true; é sem custo adicional no RDS."
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Dias de retenção de backup automático. 0 desliga os backups. Contas no plano Free da AWS aceitam no máximo 1."
  type        = number
  default     = 1

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period deve estar entre 0 e 35 dias."
  }
}

variable "tags" {
  description = "Tags aplicadas aos recursos."
  type        = map(string)
  default     = {}
}
