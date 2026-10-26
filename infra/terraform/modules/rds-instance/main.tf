############################################
# Instância RDS PostgreSQL dedicada a UM serviço.
#
# Isolamento FÍSICO: cada serviço tem sua própria instância, com subnet group,
# security group, endpoint e credencial master próprios. Uma instância não
# alcança os dados da outra — não há acesso cruzado por construção.
############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name    = "${var.identifier}-subnet-group"
    Service = var.service
  })
}

# SG sem ingress aberto: a porta 5432 só é liberada para o node SG do EKS e,
# opcionalmente, para CIDRs explícitos. Sem regra 0.0.0.0/0.
resource "aws_security_group" "this" {
  name        = "${var.identifier}-security-group"
  description = "Acesso ao RDS de ${var.service} (somente nos do EKS / CIDRs explicitos)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name    = "${var.identifier}-security-group"
    Service = var.service
  })
}

resource "aws_security_group_rule" "from_eks_nodes" {
  count = var.node_security_group_id != null ? 1 : 0

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.node_security_group_id
  description              = "PostgreSQL dos nos do EKS"
}

resource "aws_security_group_rule" "from_allowed_cidrs" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = var.allowed_cidr_blocks
  description       = "PostgreSQL de CIDRs explicitamente liberados"
}

resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine         = "postgres"
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  # O database inicial do serviço e a credencial master são criados pela própria
  # instância — cada serviço com seu banco e suas credenciais.
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  publicly_accessible = var.publicly_accessible

  # Criptografia em repouso (sem custo adicional) + backups automáticos.
  storage_encrypted       = var.storage_encrypted
  backup_retention_period = var.backup_retention_period

  skip_final_snapshot = true
  deletion_protection = false
  apply_immediately   = true

  tags = merge(var.tags, {
    Name    = var.identifier
    Service = var.service
  })
}
