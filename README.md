# Terraform script to deploy AWS infra:

- AWS VPC and the associated components
- EKS cluster
- Cluster and node security groups
- EBS CSI driver
- Scaling configuration
- Cluster IAM role and policy configurations and attachment



# The goal of this repo is to implement "HashiCorp Vault with Raft HA" 

- The vault will be installed using Helm on a "control server"
- The Secrets Engines of the vault will store the sensitive data of the application, and proper authentication and authorization via best practice will be configured (Dev/QA/Prod). vault-0, vault-1, and vault-2

- Step-by-step documentation and code used will be added to this repo soon... Please follow to get more details.

- Thank you!