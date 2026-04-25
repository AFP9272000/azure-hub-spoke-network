# Azure Hub-Spoke Network Security — Project File Tree

```
azure-hub-spoke-network/
├── README.md
├── .gitignore
│
├── terraform/
│   ├── main.tf                          # Root module - orchestrates all modules
│   ├── variables.tf                     # Root input variables
│   ├── outputs.tf                       # Root outputs
│   ├── providers.tf                     # AzureRM provider + backend config
│   ├── backend.tf                       # Remote state configuration
│   ├── terraform.tfvars                 # Default variable values
│   │
│   ├── modules/
│   │   ├── hub-network/
│   │   │   ├── main.tf                  # Hub VNet, subnets, Bastion, NSG
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── firewall/
│   │   │   ├── main.tf                  # Azure Firewall, policy, rule collections
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── spoke-network/
│   │   │   ├── main.tf                  # Spoke VNet, peering, UDR, NSG (reusable)
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── storage/
│   │   │   ├── main.tf                  # Storage account, private endpoint, DNS zone
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── app-service/
│   │   │   ├── main.tf                  # App Service for web spoke
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── front-door/
│   │   │   ├── main.tf                  # Front Door, WAF policy, custom rules
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   └── monitoring/
│   │       ├── main.tf                  # Flow logs, diagnostics, alerts, Log Analytics
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   └── environments/
│       └── dev/
│           └── terraform.tfvars         # Dev environment overrides
│
├── bicep/
│   ├── main.bicep                       # Main deployment orchestrator
│   ├── parameters/
│   │   └── dev.bicepparam               # Dev environment parameters
│   │
│   └── modules/
│       ├── hub-network.bicep            # Hub VNet, subnets, Bastion, NSG
│       ├── firewall.bicep               # Azure Firewall, policy, rule collections
│       ├── spoke-network.bicep          # Spoke VNet, peering, UDR, NSG
│       ├── storage.bicep                # Storage account, private endpoint, DNS zone
│       ├── app-service.bicep            # App Service for web spoke
│       ├── front-door.bicep             # Front Door, WAF policy, custom rules
│       └── monitoring.bicep             # Flow logs, diagnostics, alerts
│
├── pipelines/
│   ├── github-actions/
│   │   └── terraform-deploy.yml         # Terraform CI/CD with OIDC + security scanning
│   │
│   └── azure-devops/
│       └── bicep-deploy.yml             # Bicep CI/CD with OIDC
│
└── docs/
    ├── FILE_TREE.md                     # This file
    ├── ARCHITECTURE.md                  # Architecture diagram and design decisions
    └── TESTING.md                       # Attack simulation and verification procedures
```
