output "rds_endpoint" {
  description = "Endpoint (host:porta) de conexão com o banco RDS."
  value       = aws_db_instance.this.endpoint
}

output "rds_address" {
  description = "Host do RDS, sem a porta. Valor do secret DB_HOST do repositório TechChallenger-Api e da Lambda de autenticação."
  value       = aws_db_instance.this.address
}

output "rds_port" {
  description = "Porta de conexão do RDS."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nome do banco de dados no RDS."
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Usuário administrador do RDS (sensível)."
  value       = var.db_username
  sensitive   = true
}

output "db_password" {
  description = "Senha do usuário administrador do RDS (sensível)."
  value       = var.db_password
  sensitive   = true
}

output "rds_security_group_id" {
  description = "ID do security group do RDS."
  value       = aws_security_group.rds.id
}

output "rds_client_security_group_id" {
  description = "ID do SG rds-client. Consumidores do banco fora do EKS (ex.: Lambda de autenticação) associam este SG às suas ENIs para ganhar acesso ao RDS (ver ADR-002)."
  value       = aws_security_group.rds_client.id
}
