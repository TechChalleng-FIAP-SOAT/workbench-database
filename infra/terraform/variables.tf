variable "region" {
  description = "Região da AWS"
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente (develop/main). Compõe os identificadores das instâncias e a key do estado remoto do k8s."
  type        = string
  default     = "develop"
}

variable "name_prefix" {
  description = "Prefixo dos identificadores das instâncias RDS (ex.: workshop -> workshop-os_service-main)."
  type        = string
  default     = "workshop"
}

variable "aws_account_id" {
  description = "Expected AWS account ID. Guards the provider against deploying to the wrong account. Empty = no restriction (local validation)."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Rede. vpc_id/subnet_ids são opcionais: quando vazios, são resolvidos pelo
# estado remoto do workbench-k8s-terraform (ver k8s_remote_state_bucket).
# -----------------------------------------------------------------------------
variable "vpc_id" {
  description = "ID da VPC existente. Vazio = resolvido pelo estado remoto do k8s."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnets privadas para o RDS. Vazio = private_subnet_ids do estado remoto do k8s."
  type        = list(string)
  default     = []
}

variable "k8s_remote_state_bucket" {
  description = "Bucket S3 do estado do workbench-k8s-terraform. Preenchido = lê vpc/subnets/node SG de lá; vazio = usa vpc_id/subnet_ids passados por variável."
  type        = string
  default     = ""
}

variable "publicly_accessible" {
  description = "Expõe as instâncias RDS publicamente. Mantenha false: o acesso deve vir apenas dos nós do EKS (mesma VPC)."
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "CIDRs extras liberados na porta 5432 em TODAS as instâncias (ex.: runner de migração com acesso à VPC). Vazio = acesso só pelo node SG do EKS."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Um bloco por serviço: cada entrada vira uma INSTÂNCIA RDS dedicada, com banco,
# credencial e sizing próprios. As chaves (os_service/billing/customer) e os
# db_name devem casar com o SPRING_DATASOURCE_URL de cada serviço.
# As senhas são injetadas pelo CI via TF_VAR_services ou arquivo tfvars (nunca
# commitadas) — ver terraform.tfvars.example.
# -----------------------------------------------------------------------------
variable "services" {
  description = "Mapa serviço -> configuração da sua instância RDS dedicada (sem senha; a senha vem de var.service_passwords)."
  type = map(object({
    db_name           = string
    db_username       = string
    instance_class    = optional(string, "db.t3.micro")
    allocated_storage = optional(number, 20)
  }))

  validation {
    condition     = length(var.services) >= 1
    error_message = "Defina ao menos um serviço em var.services."
  }
}

variable "service_passwords" {
  description = "Mapa serviço -> senha master da instância daquele serviço. As chaves devem casar com var.services. Injetado pelo CI (secret); nunca commitado."
  type        = map(string)
  sensitive   = true

  validation {
    condition     = length(var.service_passwords) >= 1
    error_message = "Defina a senha de cada serviço em var.service_passwords."
  }
}
