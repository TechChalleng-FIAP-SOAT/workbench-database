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

variable "tags" {
  description = "Tags aplicadas aos recursos."
  type        = map(string)
  default     = {}
}
