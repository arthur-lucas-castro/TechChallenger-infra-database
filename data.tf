data "terraform_remote_state" "kubernetes" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket
    key    = var.kubernetes_state_key
    region = "us-east-1"
  }
}

locals {
  vpc_id                        = data.terraform_remote_state.kubernetes.outputs.vpc_id
  private_subnet_ids            = data.terraform_remote_state.kubernetes.outputs.private_subnet_ids
  eks_cluster_security_group_id = data.terraform_remote_state.kubernetes.outputs.eks_cluster_security_group_id
}
