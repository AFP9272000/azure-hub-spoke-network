# Azure Hub-Spoke Network Architecture with Firewall + WAF

Enterprise hub-spoke network topology with centralized Azure Firewall controlling all east-west and north-south traffic, Azure Front Door + WAF protecting a public-facing web app, VNet flow logs for traffic analysis, and micro-segmentation — the complete network security stack that every enterprise Azure environment runs.

![Azure](https://img.shields.io/badge/Azure-Firewall%20%7C%20Front%20Door%20%7C%20Bastion-0078D4)
![IaC](https://img.shields.io/badge/IaC-Terraform%20%2B%20Bicep-purple)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20%2B%20Azure%20DevOps-green)
![Security](https://img.shields.io/badge/Security-Checkov%20%7C%20tfsec%20%7C%20Trivy%20%7C%20TFLint-red)
![Auth](https://img.shields.io/badge/Auth-OIDC%20%7C%20Zero%20Secrets-brightgreen)
![WAF](https://img.shields.io/badge/WAF-SQLi%20%7C%20XSS%20%7C%20Rate%20Limit%20%7C%20Geo--Filter-orange)

## Overview

A production-grade hub-spoke network architecture deployed on Azure with centralized firewall inspection, WAF perimeter defense, private endpoint connectivity, and comprehensive traffic monitoring — built with dual IaC implementations (Terraform + Bicep) and dual CI/CD pipelines (GitHub Actions + Azure DevOps), both authenticated via OIDC Workload Identity Federation with zero stored secrets.

**Key Metrics:**
- Enforces **zero-trust network segmentation** across 3 VNets with all traffic routed through Azure Firewall
- Blocks **5 attack categories** via custom WAF rules (SQLi, XSS, path traversal, rate limiting, geo-filtering)
- Monitors **all VNet traffic** via VNet Flow Logs with Traffic Analytics at 10-minute intervals
- Implements **micro-segmentation** — web→data allowed on SQL (1433) and HTTPS (443) only, reverse denied
- Achieves **zero stored secrets** via OIDC federation across all CI/CD authentication flows
- Passes **quad-layer security scanning** (Checkov, tfsec, Trivy, TFLint) on every deployment
- Dual IaC: identical infrastructure deployable via **Terraform or Bicep**
- Dual CI/CD: full pipelines on both **GitHub Actions and Azure DevOps**

## Architecture

<!-- Replace with your actual Draw.io diagram screenshot -->
<img alt="hub-spoke-architecture" src="docs/architecture.drawio.png" />

## Network Security Controls

| Layer | Control | Implementation |
|-------|---------|---------------|
| **Perimeter** | Azure Front Door + WAF | Custom rules: SQLi, XSS, path traversal, rate limiting (100 req/min), geo-filtering |
| **Network** | Azure Firewall | Application rules (FQDN filtering), Network rules (port-level), DNAT, Threat Intelligence deny |
| **Segmentation** | Hub-Spoke + UDRs | All traffic forced through firewall, no spoke-to-spoke peering |
| **Micro-segmentation** | Firewall Rules | Web→Data on SQL (1433) and HTTPS (443) only, Data→Web denied |
| **Access** | Azure Bastion | No public IPs on VMs, browser-based SSH over TLS |
| **Data** | Private Endpoints | Storage accessible only via Private Link, public access disabled |
| **Monitoring** | VNet Flow Logs + Traffic Analytics | All VNets monitored, 10-minute analytics interval |
| **Alerting** | Azure Monitor | Denied traffic spikes, WAF block spikes |

## Zero Trust Implementation

| Principle | Implementation |
|-----------|---------------|
| **Deny-all baseline** | Firewall blocks everything not explicitly allowed |
| **Least privilege** | Data spoke: Azure API access only. Web spoke: GitHub/Docker/Azure |
| **One-directional flow** | Web→Data allowed, Data→Web explicitly denied |
| **No public IPs** | All VM access through Bastion over TLS |
| **Private connectivity** | Storage via Private Endpoint only, public access disabled |
| **Threat intelligence** | Firewall auto-blocks known malicious IPs/domains |
| **Perimeter defense** | WAF inspects all inbound traffic before reaching application |

## WAF Custom Rules

| Rule | Type | Match Variable | Detection | Action |
|------|------|---------------|-----------|--------|
| **RateLimitPerIP** | Rate Limit | RequestUri | >100 requests/min per IP | Block |
| **GeoBlock** | Match | RemoteAddr | Geo-match on blocked countries | Block |
| **BlockKnownBadPatterns** | Match | RequestUri | `../`, `etc/passwd`, `<script>` | Block |
| **BlockSQLInjection** | Match | QueryString | `' or`, `1=1`, `union select`, `drop table`, `--` | Block |
| **BlockXSS** | Match | QueryString | `<script>`, `javascript:`, `onerror=` | Block |

All rules use **UrlDecode + Lowercase** transforms to catch encoded attack payloads.

## Infrastructure as Code

This project demonstrates **dual IaC proficiency** with identical infrastructure deployable via either tool:

### Terraform

```
terraform/
├── main.tf                          # Root orchestration
├── variables.tf                     # Input parameters
├── outputs.tf                       # Deployment outputs
├── providers.tf                     # AzureRM + AzAPI + backend config
├── backend.tf                       # Remote state configuration
└── modules/
    ├── hub-network/                 # Hub VNet, subnets, Bastion, NSG,
    │                                #   route table, management VM
    ├── firewall/                    # Azure Firewall, policy, application rules,
    │                                #   network rules, DNAT rules, threat intel
    ├── spoke-network/               # Reusable spoke module: VNet, peering,
    │                                #   UDR, NSG, optional test VM
    ├── storage/                     # Storage account, private endpoint,
    │                                #   Private DNS zone, VNet links
    ├── app-service/                 # App Service Plan + Linux Web App
    ├── front-door/                  # Front Door profile, endpoint, origin group,
    │                                #   route, WAF policy, 5 custom rules,
    │                                #   security policy association
    └── monitoring/                  # Log Analytics, VNet flow logs (AzAPI),
                                     #   diagnostic settings, alert rules,
                                     #   action groups
```

**Backend:** Remote state in Azure Storage Account with blob encryption

**Provider:** AzureRM for core resources + AzAPI for VNet flow logs (provider gap)

### Bicep

```
bicep/
├── main.bicep                       # Subscription-scoped orchestration
├── parameters/
│   └── dev.bicepparam               # Dev environment parameters
└── modules/
    ├── hub-network.bicep            # Hub VNet, subnets, Bastion, NSG, VM
    ├── firewall.bicep               # Azure Firewall + policy + all rule collections
    ├── spoke-network.bicep          # Reusable spoke (VNet, peering, UDR, NSG, VM)
    ├── storage.bicep                # Storage + private endpoint + DNS zone
    ├── app-service.bicep            # App Service Plan + Web App
    ├── front-door.bicep             # Front Door + WAF + custom rules
    └── monitoring.bicep             # Log Analytics, flow logs, diagnostics, alerts
```

**Deployment:** Single `az deployment sub create` deploys entire environment

## CI/CD Pipelines

### GitHub Actions (`pipelines/github-actions/terraform-deploy.yml`)

| Stage | Actions | Gate |
|-------|---------|------|
| **Security Scanning** | Checkov (SARIF), tfsec (SARIF), Trivy (config), TFLint | Uploads to GitHub Security |
| **Terraform Plan** | `init` → `plan` with OIDC auth | Requires security scan pass |
| **Terraform Apply** | Apply saved plan | Main branch + push only |

**Authentication:** GitHub OIDC → Azure AD federated credentials (zero secrets)

### Azure DevOps (`pipelines/azure-devops/bicep-deploy.yml`)

| Stage | Actions | Gate |
|-------|---------|------|
| **Validate & Scan** | `bicep build`, `what-if` preview, Checkov, Trivy | Blocks on failures |
| **Deploy** | `az deployment sub create` with OIDC | Main branch only |
| **Verify** | Resource list, firewall status, Front Door status | Post-deploy validation |

**Authentication:** Azure DevOps Workload Identity federation via service connection (zero secrets)

## KQL Queries

### Firewall Analytics
| Query | Description |
|-------|-------------|
| **Top Talkers** | Most active source IPs by request count |
| **Denied Traffic Patterns** | Denied flows grouped by source, destination, and port |
| **Cross-Spoke Communication** | Web↔Data spoke traffic through firewall |
| **Suspicious Spikes** | Denied flow count exceeding threshold per 5-minute window |

### WAF Analytics
| Query | Description |
|-------|-------------|
| **Blocked Requests** | All WAF-blocked requests with rule name and client IP |

### Alert Rules
| Alert | Trigger | Severity |
|-------|---------|----------|
| **Denied Traffic Spike** | >50 denied flows in 5 minutes | Warning |
| **WAF Blocks Spike** | >20 WAF blocks in 5 minutes | Warning |

## AWS ↔ Azure Parallels

| Concept | AWS (3-Tier Architecture) | Azure (Hub-Spoke) |
|---------|--------------------------|-------------------|
| Network isolation | VPC + public/private subnets | Hub-Spoke VNets + peering |
| Traffic control | Security Groups + NACLs | NSGs + Azure Firewall + UDRs |
| Perimeter defense | CloudFront + WAF | Front Door + WAF |
| Secure access | SSM Session Manager | Azure Bastion |
| Flow logging | VPC Flow Logs | VNet Flow Logs + Traffic Analytics |
| Private connectivity | VPC Endpoints | Private Endpoints + Private Link |

## Quick Start

### Prerequisites
- Azure subscription (Pay-As-You-Go or higher)
- Azure CLI installed
- Terraform >= 1.5.0
- GitHub account (for Actions pipeline)
- Azure DevOps organization (for DevOps pipeline)
- OIDC configured for both platforms

### Deploy with Terraform

```bash
# Clone repository
git clone https://github.com/AFP9272000/azure-hub-spoke-network.git
cd azure-hub-spoke-network/terraform

# Create backend storage (one-time)
az group create --name rg-terraform-state --location eastus
az storage account create --name sthubspoketerraform --resource-group rg-terraform-state \
  --sku Standard_LRS --allow-blob-public-access false
az storage container create --name tfstate --account-name sthubspoketerraform --auth-mode login

# Initialize and deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Deploy with Bicep

```bash
az deployment sub create --location eastus \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/dev.bicepparam \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
```

## Cost Management

| Resource | Hourly Cost | Daily Cost | Optimization |
|----------|-------------|------------|--------------|
| Azure Firewall Standard | $1.25 | $30.00 | Deallocate via CLI when not in use |
| Azure Bastion Basic | $0.19 | $4.50 | Delete when not in use (no deallocate) |
| VM (D2s_v3) | $0.096 | $2.30 | Deallocate + auto-shutdown |
| Front Door Standard | $0.015 | $0.35 | Low cost, leave running |
| App Service (F1) | Free | Free | — |

```bash
# Deallocate firewall
az network firewall ip-config delete --firewall-name fw-hub \
  --resource-group hub-spoke-rg --name fw-ip-config

# Delete Bastion (no deallocate option)
az network bastion delete --name bastion-hub --resource-group hub-spoke-rg

# Deallocate VMs
az vm deallocate --name vm-web-test --resource-group hub-spoke-rg
az vm deallocate --name vm-mgmt-test --resource-group hub-spoke-rg
```

## Project Structure

```
azure-hub-spoke-network/
├── terraform/                       # Terraform IaC (7 modules)
│   ├── modules/
│   │   ├── hub-network/
│   │   ├── firewall/
│   │   ├── spoke-network/
│   │   ├── storage/
│   │   ├── app-service/
│   │   ├── front-door/
│   │   └── monitoring/
│   └── environments/dev/
├── bicep/                           # Bicep IaC (7 modules)
│   ├── modules/
│   └── parameters/
├── pipelines/
│   ├── github-actions/              # Terraform CI/CD (OIDC + scanning)
│   └── azure-devops/                # Bicep CI/CD (OIDC + scanning)
└── docs/
    ├── ARCHITECTURE.md              # Design decisions
    ├── TESTING.md                   # Attack simulation procedures
    └── FILE_TREE.md                 # Complete file tree
```

## Skills Demonstrated

| Category | Technologies |
|----------|-------------|
| **Azure Networking** | VNet design, peering, UDRs, forced tunneling, hub-spoke topology |
| **Azure Security** | Azure Firewall (network/application/NAT/DNAT rules), Front Door + WAF, Bastion, Private Endpoints, Private Link, Private DNS Zones, threat intelligence |
| **Zero Trust** | Deny-all baseline, micro-segmentation, least privilege outbound, one-directional traffic, no public IPs |
| **IaC** | Terraform (modular, remote state, AzAPI provider) + Bicep (subscription-scoped, parameterized) |
| **CI/CD** | GitHub Actions (OIDC) + Azure DevOps (Workload Identity) |
| **Security Scanning** | Checkov, tfsec, Trivy, TFLint (quad-layer) |
| **Monitoring** | VNet Flow Logs, Traffic Analytics, Log Analytics, KQL, Azure Monitor alerts |
| **Languages** | HCL, Bicep, KQL, YAML, Bash, PowerShell |

## Related Projects

- [Azure Security Dashboard](https://github.com/AFP9272000/azure-security-dashboard) — AKS-based SOC platform with Defender for Cloud integration
- [Azure Sentinel SIEM](https://github.com/AFP9272000/azure-sentinel-siem) — 11 custom KQL analytics rules with MITRE ATT&CK mapping and Logic Apps playbooks
- [CloudTrail Security Monitor](https://github.com/AFP9272000/cloudtrail-security-monitor) — AWS real-time security monitoring with Lambda, Security Hub, and EventBridge
- [Security Event Aggregator](https://github.com/AFP9272000/security-event-aggregator) — Containerized microservices on ECS Fargate with MITRE ATT&CK mappings

## License

MIT License - see [LICENSE](LICENSE) for details.

---

**Addison Pirlo** — [LinkedIn](https://www.linkedin.com/in/addison-pirlo-98b1a8297/) | [Email](mailto:addisonpirlo2@gmail.com)
