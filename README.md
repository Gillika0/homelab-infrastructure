# 🏠 Homelab Infrastructure & Hybrid Cloud

Personal mini-datacenter running 24/7 — 3 on-premise nodes + 1 cloud VPS, fully automated with Ansible, containerized with Podman/Docker, and connected via zero-trust VPN mesh.

## 📐 Architecture Overview

```text
                         INTERNET
                             │
                  ┌──────────▼───────────┐
                  │   Oracle Cloud VPS   │
                  │   (Node04)           │
                  │   Ubuntu 24.04       │
                  │   ARM A1 4vCPU 24GB  │
                  │                      │
                  │   Public entry point │
                  │   Nginx Reverse Proxy│
                  │   AI workloads       │
                  └─────────┬────────────┘
                            │
                    Tailscale Mesh VPN
                    (Zero-trust, E2E encrypted)
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
┌─────────▼───────┐ ┌───────▼────────┐ ┌──────▼─────────┐
│    Node01       │ │    Node02      │ │    Node03      │
│  Rocky Linux 10 │ │ Rocky Linux 10 │ │ Rocky Linux 10 │
│  i3-7th 16GB    │ │  i3-7th 16GB   │ │  i3-7th 16GB   │
│                 │ │                │ │                │
│  Orchestration  │ │  Photo storage │ │  Media server  │
│  Observability  │ │  Self-hosted   │ │  Streaming     │
│  AI/LLM proxy   │ │  cloud storage │ │  DNS (Pi-hole) │
└─────────────────┘ └────────────────┘ └────────────────┘
```

## 🖥️ Node Details

### Node04 — Oracle Cloud VPS ☁️

| Spec | Value |
| :--- | :--- |
| **CPU** | ARM Ampere A1 — 4 vCPU |
| **RAM** | 24 GB |
| **Storage** | 200 GB SSD |
| **OS** | Ubuntu 24.04 LTS |
| **Role** | Public entry point, Reverse Proxy, AI inference |

**Running services:**
- `nginx` — Reverse proxy with automated Let's Encrypt SSL.
- `ollama` — Local LLM inference (systemd service).
- `glances` — System monitoring.
- Custom Telegram bots.

---

### Node01 — Orchestration & Observability Hub 🧠

| Spec | Value |
| :--- | :--- |
| **CPU** | Intel i3 7th Gen — 4 threads |
| **RAM** | 16 GB |
| **Storage** | NVMe 238GB + 1TB USB (ZFS formatted) |
| **OS** | Rocky Linux 10.1 (kernel 6.12) |
| **Role** | Central orchestration, AI proxy, home automation, monitoring |

**Running services:**
- `portainer` — Container management UI.
- `litellm` — Multi-model LLM proxy (Groq, Gemini, OpenRouter).
- `homeassistant` — Home automation.
- `n8n` — Workflow automation.
- `prometheus` & `loki` & `grafana` — Centralized observability stack with Telegram alerting.

---

### Node02 — Storage Node 📦

| Spec | Value |
| :--- | :--- |
| **CPU** | Intel i3 7th Gen — 4 threads |
| **RAM** | 16 GB |
| **Storage** | NVMe 238GB + 1TB USB (ZFS formatted) |
| **OS** | Rocky Linux 10.1 (kernel 6.12) |
| **Role** | Self-hosted photo/video cloud storage |

**Running services:**
- `immich` — Self-hosted Google Photos alternative (server + ML + Redis + PostgreSQL).
- `dashy` — Homepage dashboard.
- `samba` — Local LAN file sharing.

---

### Node03 — Media & Network Services 🎬

| Spec | Value |
| :--- | :--- |
| **CPU** | Intel i3 7th Gen — 4 threads |
| **RAM** | 16 GB |
| **Storage** | NVMe 238GB + 2x 1TB USB (ZFS formatted) |
| **OS** | Rocky Linux 10.1 (kernel 6.12) |
| **Role** | Media streaming, Network DNS |

**Running services:**
- `jellyfin` — Self-hosted media server.
- `pi-hole` — Network-wide ad blocking and local DNS (with automated systemd restart policy).

---

## 🛠️ Tech Stack

### Infrastructure & Orchestration

| Tool | Purpose |
| :--- | :--- |
| **Ansible** | Configuration management, cluster automation (Static inventory, managed via WSL). |
| **Podman** | Rootless container runtime managed by `systemd` (on-premise nodes). |
| **Docker** | Container runtime (Oracle VPS). |
| **ZFS** | Advanced file system ensuring data integrity on local drives. |

### Networking & Security

| Tool | Purpose |
| :--- | :--- |
| **Tailscale** | Zero-trust mesh VPN across all nodes for secure SSH and inter-node communication. |
| **Nginx & Let's Encrypt** | Reverse proxy handling public ingress with automatic SSL provisioning. |
| **Pi-hole** | Local DNS and ad-blocking with high availability auto-restart. |

### AI / LLM Stack

| Tool | Purpose |
| :--- | :--- |
| **LiteLLM** | Unified proxy for multiple LLM providers. |
| **Ollama** | Local LLM inference on Oracle ARM. |
| **n8n** | AI workflow automation. |
| **Groq / Gemini / OpenRouter API** | Cloud AI inference routing. |

### Monitoring & Backup

| Tool | Purpose |
| :--- | :--- |
| **Grafana / Prometheus / Loki** | Centralized observability stack with Telegram alert integration. |
| **Rsync & Cron** | Automated daily backups of critical configs (e.g., Home Assistant) with a strict 7-day retention policy. |

---

## 🌐 Network Design

**Physical Layer:**
All three local Lenovo nodes are connected to a **dedicated physical switch** to isolate high-throughput inter-node traffic (Samba file sharing, backups) and prevent bottlenecking the main home router.

**Home Network (LAN):**
```text
├── Node01 192.168.x.x
├── Node02 192.168.x.x
└── Node03 192.168.x.x
```

**Tailscale Overlay Network (100.x.x.x range):**
```text
├── Node01 100.x.x.x
├── Node02 100.x.x.x
├── Node03 100.x.x.x
├── Node04 100.x.x.x (Oracle)
└── Personal devices (laptop, phone, tablet)
```

**Security model:**
- **Zero-Trust:** On-premise nodes are NOT exposed to the internet. Zero open ports on the local router.
- **Ingress:** Oracle VPS is the ONLY public-facing node.
- **Access Control:** Tailscale ACLs are strictly configured to manage SSH access.

---

## 📂 Repository Structure

```text
homelab-infrastructure/
│
├── ansible/
│   ├── inventory/
│   │   └── hosts.example.ini     # Template — never commit real inventory
│   ├── playbooks/
│   │   ├── setup-nodes.yml       # Initial node setup
│   │   ├── deploy-containers.yml # Container deployment
│   │   └── update-all.yml        # Rolling updates
│   └── roles/
│       ├── common/               # Base config for all nodes
│       ├── podman/               # Podman setup
│       └── tailscale/            # Tailscale installation
│
├── containers/
│   ├── node01/                   # LiteLLM, n8n, HA, Monitoring stack
│   ├── node02/                   # Immich stack
│   ├── node03/                   # Jellyfin, Pi-hole
│   └── node04/                   # Oracle VPS services, Nginx
│
├── docs/
│   └── architecture/             # Diagrams and design decisions
│
├── scripts/
│   ├── backup.sh                 # Automated 7-day retention Rsync via cron
│   └── health-check.sh           # Cluster health check
│
├── .env.example                  # Template for environment variables
├── .gitignore                    # Excludes .env, inventory, secrets
└── README.md
```

---

## 🔒 Security Practices

- **No secrets in repository:** All credentials via environment variables.
- **Ansible Vault:** Encrypted inventory and sensitive variables.
- **Rootless Podman:** Containers run without root privileges on-premise, managed via systemd.
- **Firewalld:** Active on all Rocky Linux nodes, strictly configured.
- **git-secrets:** Pre-commit hook to prevent accidental credential leaks.

---

## 🎯 Skills Demonstrated

`Linux Administration` `Rocky Linux / RHEL` `Systemd` `Container Orchestration` `Ansible IaC` `Podman` `Docker` `Networking` `Tailscale` `Zero-Trust` `ZFS` `AI/LLM Integration` `Automation` `Observability` `Disaster Recovery`

---

## 🎓 Background

Electronic & Communication Engineering graduate (Politecnico di Torino).
Currently pursuing an MSc in Communication Engineering at PoliTo / KIT Karlsruhe.

Building this homelab to gain hands-on System Engineering, DevOps, and modern Infrastructure-as-Code experience to bridge the gap between telecommunications theory and applied cloud infrastructures.

---

## 🚀 What's Next

- **Gitea + Woodpecker CI** — Self-hosted Git and CI/CD pipeline.
- **Headscale** — Self-hosted Tailscale coordination server.
- **k3s** — Kubernetes learning cluster migration.
- **RHCSA** certification preparation.

---

> **Note:** All IP addresses, hostnames, and credentials have been removed from this repository. See `.env.example` and `hosts.example.ini` for configuration templates.
