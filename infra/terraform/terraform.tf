terraform {
  backend "s3" {}
}

resource "null_resource" "teste" {
  provisioner "local-exec" {
    command = "echo Terraform está funcionando!"
  }
}
