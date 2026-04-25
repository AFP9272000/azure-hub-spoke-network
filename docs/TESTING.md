# Attack Simulation & Verification Procedures

## Phase 1 — Firewall Traffic Control

### Allowed Traffic (via Bastion → VM)
```bash
curl -s https://www.microsoft.com -o /dev/null -w "%{http_code}"
# Expected: 200 (allowed by app-rules-baseline)
```

### Blocked Traffic
```bash
curl -s https://www.reddit.com -o /dev/null -w "%{http_code}"
# Expected: 000 (not in allowed FQDNs, blocked by firewall)
```

## Phase 2 — Spoke Routing Verification

### Web Spoke → Internet (via Bastion → vm-web-test)
```bash
curl -s https://www.microsoft.com -o /dev/null -w "%{http_code}"  # 200
curl -s https://github.com -o /dev/null -w "%{http_code}"          # 200
curl -s https://www.reddit.com -o /dev/null -w "%{http_code}"      # 000
```

### Web Spoke → Data Spoke (Private Endpoint)
```bash
nslookup sthubspokedata.blob.core.windows.net
# Expected: resolves to 10.2.1.x (private endpoint IP)

curl -s https://sthubspokedata.blob.core.windows.net -o /dev/null -w "%{http_code}"
# Expected: 409 or similar (connected but no auth — proves network path works)
```

## Phase 3 — Zero Trust Firewall Rules

### Micro-segmentation: Web → Data on allowed ports only
```bash
# From vm-web-test — SQL port should be reachable
nc -zv 10.2.1.4 1433
# Expected: Connection succeeded (allowed by net-rules-web-to-data)

# From vm-web-test — arbitrary port should be blocked
nc -zv 10.2.1.4 8080
# Expected: Connection refused (not in allowed rules)
```

### One-directional traffic enforcement
```bash
# From a hypothetical data spoke VM — traffic to web spoke should be denied
# Verified via firewall logs showing deny action for 10.2.x.x → 10.1.x.x
```

## Phase 4 — WAF Attack Simulation

### SQL Injection (from local machine)
```powershell
try {
    (Invoke-WebRequest -Uri "https://<frontdoor-endpoint>/?id=1%27%20OR%20%271%27%3D%271" -Method GET).StatusCode
} catch {
    $_.Exception.Response.StatusCode.value__
}
# Expected: 403 (blocked by BlockSQLInjection rule)
```

### Path Traversal
```powershell
try {
    (Invoke-WebRequest -Uri "https://<frontdoor-endpoint>/?file=../../etc/passwd" -Method GET).StatusCode
} catch {
    $_.Exception.Response.StatusCode.value__
}
# Expected: 403 (blocked by BlockKnownBadPatterns rule)
```

### XSS
```powershell
try {
    (Invoke-WebRequest -Uri "https://<frontdoor-endpoint>/?q=%3Cscript%3Ealert(1)%3C/script%3E" -Method GET).StatusCode
} catch {
    $_.Exception.Response.StatusCode.value__
}
# Expected: 403 (blocked by BlockXSS rule)
```

### Normal Traffic (should pass through)
```powershell
(Invoke-WebRequest -Uri "https://<frontdoor-endpoint>/" -Method GET).StatusCode
# Expected: 200 (allowed, reaches App Service)
```

## Phase 5 — Log Verification KQL Queries

### All Firewall Activity
```kql
AzureDiagnostics
| where ResourceType == "AZUREFIREWALLS"
| where TimeGenerated > ago(1h)
| project TimeGenerated, Category, msg_s
| order by TimeGenerated desc
```

### Top Talkers
```kql
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule"
| where TimeGenerated > ago(24h)
| extend SourceIp = extract(@"from\s+(\d+\.\d+\.\d+\.\d+)", 1, msg_s)
| where isnotempty(SourceIp)
| summarize RequestCount = count() by SourceIp
| top 10 by RequestCount
```

### Denied Traffic Patterns
```kql
AzureDiagnostics
| where Category == "AzureFirewallNetworkRule" or Category == "AzureFirewallApplicationRule"
| where TimeGenerated > ago(24h)
| where msg_s has "Deny"
| project TimeGenerated, Category, msg_s
| order by TimeGenerated desc
```

### Cross-Spoke Communication
```kql
AzureDiagnostics
| where Category == "AzureFirewallNetworkRule"
| where TimeGenerated > ago(24h)
| where msg_s has "10.1." and msg_s has "10.2."
| project TimeGenerated, msg_s
```

### WAF Blocked Requests
```kql
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where TimeGenerated > ago(24h)
| project TimeGenerated, msg_s
```

### Suspicious Connection Spikes
```kql
AzureDiagnostics
| where Category == "AzureFirewallNetworkRule" or Category == "AzureFirewallApplicationRule"
| where TimeGenerated > ago(24h)
| where msg_s has "Deny"
| summarize DeniedCount = count() by bin(TimeGenerated, 5m)
| where DeniedCount > 10
```

## Screenshots to Capture (Portfolio)

1. Network Watcher Topology view showing hub-spoke layout
2. Traffic Analytics map showing traffic flows between VNets
3. Firewall logs showing allowed and denied traffic side by side
4. WAF logs showing blocked SQLi/XSS/path traversal attempts
5. Azure Monitor alert configuration
6. Front Door health probe status showing healthy origin
7. Private Endpoint DNS resolution (nslookup showing private IP)
8. Bastion browser-based SSH session (no public IP)
