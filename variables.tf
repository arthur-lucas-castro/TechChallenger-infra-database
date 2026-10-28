variable "cluster_name" {
  description = "Nome do projeto/cluster, usado como prefixo e tag dos recursos do banco. Mantido igual ao cluster EKS para preservar os nomes dos recursos migrados do monorepo."
  type        = string
  default     = "techchallenger-fase1"
}

variable "environment" {
  description = "Nome do ambiente (ex: dev, hml, prod), usado em tags de recursos."
  type        = string
  default     = "dev"
}

variable "remote_state_bucket" {
  description = "Bucket S3 onde ficam os states remotos (criado pelo bootstrap do repositório infra-kubernetes)."
  type        = string
  default     = "techchallenger-fase1-terraform-state-shared"
}

variable "kubernetes_state_key" {
  description = "Key do state do repositório infra-kubernetes no bucket, de onde são lidos VPC, subnets privadas e SG do cluster."
  type        = string
  default     = "infra-kubernetes/terraform.tfstate"
}

variable "db_engine" {
  description = "Engine do banco RDS."
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Versão do engine do banco RDS. Deixe null para a AWS usar a versão padrão disponível no momento da criação (evita fixar uma versão que pode deixar de ser oferecida). Para fixar uma versão específica, rode \"aws rds describe-db-engine-versions --engine postgres --query 'DBEngineVersions[].EngineVersion'\" e escolha uma das listadas."
  type        = string
  default     = null
}

variable "db_port" {
  description = "Porta de conexão do banco RDS."
  type        = number
  default     = 5432
}

variable "db_instance_class" {
  description = "Instance class do RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Nome do banco de dados criado na instância RDS."
  type        = string
  default     = "techchallenger"
}

variable "db_username" {
  description = "Usuário administrador do banco RDS."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Senha do usuário administrador do banco RDS."
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Armazenamento inicial (GB) alocado para o RDS. Mínimo 20GB: é o piso exigido pela AWS para storage gp3 em instâncias Postgres."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Limite superior (GB) para o storage autoscaling do RDS. Mantido bem abaixo do limite de 100GB por volume EBS no AWS Academy Learner Lab."
  type        = number
  default     = 50
}

variable "db_backup_retention_period" {
  description = "Retenção (em dias) dos backups automáticos do RDS."
  type        = number
  default     = 7
}
