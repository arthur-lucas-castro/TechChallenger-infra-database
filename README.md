# TechChallenger-infra-database

Banco de dados gerenciado da oficina mecânica: **Amazon RDS for PostgreSQL**, provisionado com **Terraform**.

## Repositórios do projeto

| Repositório | Responsabilidade |
|---|---|
| [TechChallenger-infra-kubernetes](https://github.com/arthur-lucas-castro/TechChallenger-infra-kubernetes) | VPC, EKS, node group, ECR, bucket do state |
| **TechChallenger-infra-database** (este) | RDS PostgreSQL |
| [TechChallenger-severless](https://github.com/arthur-lucas-castro/TechChallenger-severless) | Código da Lambda de autenticação por CPF (o Terraform dela e do API Gateway fica no infra-kubernetes) |
| [TechChallenger-Api](https://github.com/arthur-lucas-castro/TechChallenger-Api) | API da oficina, schema SQL e migração |

**Ordem de provisionamento:** 1. infra-kubernetes → **2. infra-database** → 3. severless / Api.
**Ordem de destruição:** este repositório deve ser destruído **antes** do infra-kubernetes, porque o RDS usa as subnets da VPC.

## O que este repositório provisiona

| Recurso | Descrição |
|---|---|
| `aws_db_instance.this` | PostgreSQL `db.t3.micro`, gp3 criptografado, sem acesso público, backup de 7 dias |
| `aws_db_subnet_group.this` | Subnets privadas da VPC do infra-kubernetes |
| `aws_security_group.rds` | Porta 5432 liberada só para o SG do cluster EKS e para o SG da Lambda, ambos criados pelo infra-kubernetes |

```
      ┌──────── VPC (infra-kubernetes) ── subnets privadas ────────┐
      │                                                              │
      │   Nodes EKS ──(SG do cluster)──┐                             │
      │                                ├──► SG rds :5432 ──► RDS     │
      │   Lambda ─────(SG rds-client)──┘                             │
      └──────────────────────────────────────────────────────────────┘
```

## Modelo de dados e decisão do banco

| Documento | Conteúdo |
|---|---|
| [RFC-002: escolha do banco](https://github.com/arthur-lucas-castro/TechChallenger-Api/blob/main/docs/rfc/RFC-002-banco-de-dados.md) | PostgreSQL no RDS comparado com MySQL, SQL Server, Aurora e DynamoDB; justificativa de classe, armazenamento, rede e backup |
| [Modelo relacional](https://github.com/arthur-lucas-castro/TechChallenger-Api/blob/main/docs/banco-de-dados/modelo-relacional.md) | Diagrama ER, relacionamentos, ajustes feitos na Fase 3 e ajustes recomendados |
| [Documentação da arquitetura](https://github.com/arthur-lucas-castro/TechChallenger-Api/blob/main/docs/arquitetura/README.md) | Índice geral: componentes, sequência, RFCs e ADRs |

O schema fica no TechChallenger-Api (`database/init/01_schema.sql`) e as tabelas de autenticação no TechChallenger-severless (`db/migrations/`); este repositório provisiona só a instância.

## Dependências

Lê os outputs do **infra-kubernetes** via `terraform_remote_state` (`data.tf`): `vpc_id`, `private_subnet_ids`, `eks_cluster_security_group_id` e `rds_client_security_group_id`. O bucket e a key ficam nas variáveis `remote_state_bucket` e `kubernetes_state_key`.

## Outputs

| Output | Consumidor |
|---|---|
| `rds_address` | Parâmetro `/techchallenger/db/host` no SSM |
| `db_name` | Parâmetro `/techchallenger/db/name` no SSM |
| `rds_endpoint`, `rds_port` | Consulta manual |
| `db_username`, `db_password` (sensíveis) | Parâmetros `/techchallenger/db/username` e `/techchallenger/db/password` no SSM |

## Como usar

Via GitHub Actions (recomendado): workflow **Terraform Apply - RDS** (`infra-apply.yml`).

Localmente:

```bash
cp terraform.tfvars.example terraform.tfvars   # preencher db_username / db_password
terraform init && terraform apply
```

O **schema** do banco (`01_schema.sql`) fica no repositório **TechChallenger-Api**, porque evolui junto com as entidades da aplicação. Ele é aplicado pelo workflow `database-migration.yml` daquele repositório, como um Job dentro do EKS (o RDS não tem acesso público).

### Pipelines

| Workflow | Gatilho | O que faz |
|---|---|---|
| `terraform-ci.yml` | Pull request | `fmt -check` + `validate` (sem credenciais) |
| `infra-apply.yml` | Manual | `plan` → `apply` → mostra `DB_HOST`/`DB_NAME` |
| `infra-destroy.yml` | Manual | `plan -destroy` → aprovação → `destroy` |

Secrets do environment `aws-deploy`: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `DB_USER`, `DB_PASSWORD`. Variable: `MEU_USUARIO_GITHUB`.

Os parâmetros do SSM são publicados pelo workflow `ssm-parameters.yml` do [TechChallenger-infra-kubernetes](https://github.com/arthur-lucas-castro/TechChallenger-infra-kubernetes). Rode esse workflow depois do `infra-apply.yml` e, depois de recriar o RDS, informe o host de novo, porque ele pode mudar. Se a senha do banco mudar no secret `DB_PASSWORD`, publique a nova lá também.

## Decisões de design

- **Subnets privadas, sem acesso público**: só o EKS e os portadores do SG `rds-client` chegam ao banco.
- **SG `rds-client` no infra-kubernetes**: ele é criado junto com a Lambda (`rds_client_security_group_id`), e este repositório só lê o output e libera a porta. Assim o infra-kubernetes nunca depende do state daqui, e o infra-kubernetes precisa ser aplicado antes. O state do SG do RDS fica inteiro aqui, com regras inline e sem conflito entre states ([ADR-002](https://github.com/arthur-lucas-castro/TechChallenger-severless/blob/main/docs/adr/ADR-002-localizacao-terraform-lambda-api-gateway.md)).
- **`db_engine_version = null`**: a AWS usa a versão padrão do momento, o que evita erro com versão descontinuada.
- **Storage de 20GB (gp3) com autoscaling até 50GB**: 20GB é o piso da AWS para gp3 no Postgres, e o teto fica abaixo do limite de 100GB por volume do Learner Lab.
- **`skip_final_snapshot = true`**: ambiente de estudo. Em produção, usar `false` e definir `final_snapshot_identifier`.
- **Nomes dos recursos** (`techchallenger-fase1-db`, `-rds`) mantidos iguais aos do monorepo, para a migração de state não recriar nada.

## Migração do monorepo

O state destes recursos foi separado do monorepo pelo script `scripts/migrar-state-monorepo.sh` do repositório **infra-kubernetes**. Depois da migração, o primeiro `plan` deste repositório deve mostrar só a nova regra no SG do RDS.
