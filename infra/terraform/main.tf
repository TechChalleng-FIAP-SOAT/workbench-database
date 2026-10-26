############################################
# Rede resolvida (estado remoto do k8s OU variáveis)
############################################

locals {
  k8s = length(data.terraform_remote_state.k8s) > 0 ? data.terraform_remote_state.k8s[0].outputs : null

  vpc_id = var.vpc_id != "" ? var.vpc_id : (local.k8s != null ? local.k8s.vpc_id : null)

  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : (local.k8s != null ? local.k8s.private_subnet_ids : [])

  # Node SG do EKS: só existe quando lemos o estado remoto. Quando ausente,
  # o acesso depende exclusivamente de allowed_cidr_blocks.
  node_security_group_id = local.k8s != null ? local.k8s.node_security_group_id : null

  common_tags = {
    Project     = "workbench"
    Component   = "database"
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

############################################
# Uma instância RDS PostgreSQL por serviço (database-per-service, ADR Fase 4).
#
# Cada serviço (os_service, billing, customer) recebe uma INSTÂNCIA própria,
# com banco, credencial, endpoint e security group dedicados. O isolamento é
# físico: nenhuma instância alcança os dados da outra — atende literalmente o
# requisito do PDF ("cada microsserviço com banco próprio" / "nenhum serviço
# acessa o banco de outro"). O Execution Service usa MongoDB, fora deste repo.
############################################

module "service_db" {
  source   = "./modules/rds-instance"
  for_each = var.services

  service = each.key
  # Identificador RDS não aceita underscore -> troca por hífen (os_service -> os-service).
  # O db_name permanece com underscore (os_service), casando com o SPRING_DATASOURCE_URL.
  identifier  = "${var.name_prefix}-${replace(each.key, "_", "-")}-${var.environment}"
  db_name     = each.value.db_name
  db_username = each.value.db_username
  db_password = var.service_passwords[each.key]

  vpc_id                 = local.vpc_id
  subnet_ids             = local.subnet_ids
  node_security_group_id = local.node_security_group_id
  allowed_cidr_blocks    = var.allowed_cidr_blocks

  instance_class      = each.value.instance_class
  allocated_storage   = each.value.allocated_storage
  publicly_accessible = var.publicly_accessible

  tags = local.common_tags
}
