# Azure Secure Network Lab

Secure network setup built hands-on in the Azure portal: two peered VNets, subnet segmentation, an NSG with an application security group, Azure Firewall with a firewall policy, forced outbound routing through the firewall, and a private DNS zone.

> Based on the Microsoft Learn guided project [Configure secure access to workloads with Azure virtual networking services](https://learn.microsoft.com/en-us/training/modules/guided-project-configure-secure-access-workloads/). I built everything in the portal and exported the templates afterwards.

## Architecture

```mermaid
flowchart LR
    subgraph HUB["hub-vnet · 10.0.0.0/16"]
        HFWS["AzureFirewallSubnet 10.0.0.0/26<br/>(unused)"]
    end
    subgraph APP["app-vnet · 10.1.0.0/16 · DNS 1.1.1.1"]
        FE["frontend 10.1.0.0/24<br/>VM1 · ASG app-frontend-asg"]
        BE["backend 10.1.1.0/24<br/>VM2 · NSG app-vnet-nsg"]
        FW["AzureFirewallSubnet 10.1.63.0/26<br/>app-vnet-firewall · 10.1.63.4"]
    end
    HUB <-->|VNet peering| APP
    FE -->|"UDR 0.0.0.0/0"| FW
    BE -->|"UDR 0.0.0.0/0"| FW
    FW -->|"HTTPS: dev.azure.com, azure.microsoft.com<br/>UDP 53: 1.1.1.1, 1.0.0.1"| NET((Internet))
    DNS[("Private DNS zone<br/>private.contoso.com")]
```

![Topology from Azure Network Watcher](docs/topology.png)

## What I built

| Component | Configuration |
|---|---|
| VNets | `hub-vnet` 10.0.0.0/16 and `app-vnet` 10.1.0.0/16, peered in both directions |
| Subnets | `frontend` 10.1.0.0/24, `backend` 10.1.1.0/24, `AzureFirewallSubnet` 10.1.63.0/26 |
| NSG | `app-vnet-nsg` on `backend`: allow inbound SSH (22) to the ASG `app-frontend-asg` |
| ASG | `app-frontend-asg`, assigned to VM1's network interface |
| Azure Firewall | Standard tier, policy `fw-policy`, private IP 10.1.63.4 |
| Firewall rules | Application rule: HTTPS to `dev.azure.com` and `azure.microsoft.com` from 10.1.0.0/23. Network rule: DNS (UDP 53) to 1.1.1.1 / 1.0.0.1 |
| Route table | `app-vnet-firewall-rt` on `frontend` and `backend`: 0.0.0.0/0 → 10.1.63.4 (virtual appliance) |
| DNS | Custom DNS servers 1.1.1.1 / 1.0.0.1 on `app-vnet`, private DNS zone `private.contoso.com` (created, not linked to a VNet yet) |
| VMs | VM1 (frontend) and VM2 (backend), Ubuntu, Standard_D2s_v4 |

## How I tested it

| Test | How | Result |
|---|---|---|
| Outbound traffic goes through the firewall | Network Watcher → Next hop from VM1 (10.1.0.4) to 8.8.8.8 | Next hop: VirtualAppliance 10.1.63.4 ✅ |
| Allowed site is reachable | VM1 → Run command: `curl https://dev.azure.com` | HTTP 302 – allowed ✅ |
| Other sites are blocked | VM1 → Run command: `curl https://www.google.com` | HTTP 000 – blocked by the firewall ✅ |
| DNS works through the firewall | VM1 → Run command: `getent hosts dev.azure.com` | Name resolved ✅ |

### Screenshots

**VNet peering**
![VNet peering](docs/screenshots/01-peering.png)

**NSG inbound rules**
![NSG rules](docs/screenshots/02-nsg-rules.png)

**Firewall policy – application rules**
![Application rules](docs/screenshots/03-firewall-app-rules.png)

**Firewall policy – network rules**
![Network rules](docs/screenshots/04-firewall-network-rules.png)

**Route table – routes and subnets**
![Routes](docs/screenshots/05-route-table.png)
![Route table subnets](docs/screenshots/06-route-table-subnets.png)

**Private DNS zone**
![Private DNS](docs/screenshots/07-private-dns.png)

**Test: next hop**
![Next hop](docs/screenshots/08-next-hop.png)

**Test: firewall rules and DNS**
![Tests](docs/screenshots/09-tests.png)

## Lessons learned

- **Firewall placement.** In this lab the firewall sits in the app VNet, and the hub stays empty. In a real hub-and-spoke design, the firewall lives in the hub and every spoke routes to it through the peering.
- **Custom DNS vs. private DNS zones.** `app-vnet` uses 1.1.1.1 as its DNS server. VMs then can't resolve Azure private DNS zones, because only Azure's own resolver (168.63.129.16) answers for them. To use both, keep Azure DNS or add a DNS Private Resolver / forwarder. The zone also has no virtual network link yet, and a private zone only answers for VNets it's linked to.
- **SSH from anywhere.** The NSG allows port 22 from any source. That's acceptable for a short lab. In production, restrict the source, use Azure Bastion and remove public IPs from VMs.
- **Testing without SSH.** Run command let me test the firewall rules from inside the VM without opening any inbound port.
- **Lab image.** Ubuntu 18.04 is out of standard support. Use 22.04 or 24.04 for anything real.

## Cost and cleanup

Azure Firewall Standard costs about $1.25 per hour while it's deployed (roughly $900 per month), plus two VMs and three public IPs. I deleted the resource group right after testing.

## Repository contents

| Path | Content |
|---|---|
| `docs/topology.png`, `docs/topology.svg` | Topology export from Azure Network Watcher |
| `docs/screenshots/` | Configuration and test screenshots |
| `export/template.json`, `export/main.bicep` | ARM template exported from the portal and decompiled to Bicep. This is a snapshot for reference and isn't deployable as-is (no admin credentials, hardcoded disk names). |

## Next step

Rebuild the setup in Terraform, with the firewall in the hub.
