terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configurado pelo CI via -backend-config; `terraform init -backend=false`
  # funciona para validação local.
  backend "s3" {}
}

# -----------------------------------------------------------------------------
# Rede herdada do workbench-k8s-terraform (VPC + EKS). Lemos o estado remoto
# para reutilizar o node_security_group_id dos nós do EKS, de modo que só os
# pods dos serviços (na mesma VPC) alcancem o RDS. Opcional: quando
# var.k8s_remote_state_bucket está vazio, o módulo não lê o estado e cai nos
# valores passados por variável (vpc_id/subnet_ids), preservando o fluxo do CI
# atual, que injeta esses valores por secret.
# -----------------------------------------------------------------------------
data "terraform_remote_state" "k8s" {
  count = var.k8s_remote_state_bucket != "" ? 1 : 0

  backend = "s3"
  config = {
    bucket = var.k8s_remote_state_bucket
    key    = "k8s/${var.environment}/terraform.tfstate"
    region = var.region
  }
}
