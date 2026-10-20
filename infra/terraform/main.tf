############################################
# DB Subnet Group
############################################

resource "aws_db_subnet_group" "aurora_subnets" {
  name       = "aurora-${var.db_name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "Aurora Subnet Group"
  }
}

############################################
# Security Group
############################################

resource "aws_security_group" "aurora_sg" {
  name        = "aurora-${var.db_name}-security-group"
  description = "Acesso ao Aurora PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ajuste conforme sua rede
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################################
# Instancia PostgreSQL RDS para o Free Tier
############################################

resource "aws_db_instance" "postgres" {
  identifier = var.db_name

  engine         = "postgres"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.aurora_subnets.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]

  publicly_accessible     = true
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
}

############################################
# PostgreSQL DDL
############################################

resource "null_resource" "create_database" {
  triggers = {
    db_name = var.db_name
  }

  depends_on = [aws_db_instance.postgres]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      EXISTS=$(PGPASSWORD="${var.db_password}" psql \
        -v ON_ERROR_STOP=1 \
        -h "${aws_db_instance.postgres.address}" \
        -U "${var.db_username}" \
        -d postgres \
        -tAc "SELECT 1 FROM pg_database WHERE datname='${var.db_name}'")

      if [ "$EXISTS" != "1" ]; then
        PGPASSWORD="${var.db_password}" psql \
          -v ON_ERROR_STOP=1 \
          -h "${aws_db_instance.postgres.address}" \
          -U "${var.db_username}" \
          -d postgres \
          -c "CREATE DATABASE \"${var.db_name}\""
      fi
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "run_ddl" {
  count = var.run_migrations ? 1 : 0

  triggers = {
    script_hash = filesha256("${path.module}/../../scripts/ddl.sql")
  }

  depends_on = [null_resource.create_database]

  provisioner "local-exec" {
    command = <<-EOT
      PGPASSWORD="${var.db_password}" psql \
        -v ON_ERROR_STOP=1 \
        -h "${aws_db_instance.postgres.address}" \
        -U "${var.db_username}" \
        -d "${var.db_name}" \
        -f "${path.module}/../../scripts/ddl.sql"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}


############################################
# PostgreSQL DML
############################################

resource "null_resource" "run_dml" {
  count = var.run_migrations ? 1 : 0

  triggers = {
    script_hash = filesha256("${path.module}/../../scripts/dml.sql")
  }

  depends_on = [
    null_resource.run_ddl
  ]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      PGPASSWORD="${var.db_password}" psql \
        -v ON_ERROR_STOP=1 \
        -h "${aws_db_instance.postgres.address}" \
        -U "${var.db_username}" \
        -d "${var.db_name}" \
        -f "${path.module}/../../scripts/dml.sql"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

