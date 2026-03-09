# 🏠 Homelab Infrastructure

> Personal mini-datacenter running 24/7 — 3 on-premise nodes + 1 cloud VPS, fully automated with Ansible, containerized with Podman/Docker, and connected via zero-trust VPN mesh.

---

## Architecture Overview

```
                        INTERNET
                            │
                  ┌─────────▼──────────┐
                  │   Oracle Cloud VPS  │
                  │   (Node04)          │
                  │   Ubuntu 24.04      │
                  │   ARM A1 4vCPU 24GB │
                  │                     │
                  │   Public entry point│
                  │   AI workloads      │
                  │   LLM inference     │
                  └─────────┬──────────┘
                            │
                    Tailscale Mesh VPN
                    (Zero-trust, E2E encrypted)
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
┌─────────▼──────┐ ┌────────▼───────┐ ┌──────▼─────────┐
│    Node01       │ │    Node02      │ │    Node03      │
│  Rocky Linux 10 │ │ Rocky Linux 10 │ │ Rocky Linux 10 │
│  i3-7th 16GB    │ │  i3-7th 8GB    │ │  i3-7th 8GB    │
│                 │ │                │ │                │
│  Orchestration  │ │  Photo storage │ │  Media server  │
│  AI/LLM proxy   │ │  Self-hosted   │ │  Streaming     │
│  Automation     │ │  cloud storage │ │                │
└─────────────────┘ └────────────────┘ └────────────────┘
```

---

## Node Details

### Node04 — Oracle Cloud VPS ☁️
| Spec | Value |
|---|---|
| CPU | ARM Ampere A1 — 4 vCPU |
| RAM | 24 GB |
| Storage | 200 GB SSD |
| OS | Ubuntu 24.04 LTS |
| Role | Public entry point, AI inference, custom bots |

**Running services:**
- `ollama` — Local LLM inference (systemd service)
- `glances` — System monitoring
- Custom Telegram bots

---

### Node01 — Orchestration Hub 🧠
| Spec | Value |
|---|---|
| CPU | Intel i3 7th Gen — 4 threads |
| RAM | 16 GB |
| Storage | NVMe 238GB + 1TB USB |
| OS | Rocky Linux 10.1 (kernel 6.12) |
| Role | Central orchestration, AI proxy, home automation |

**Running services:**
- `portainer` — Container management UI
- `litellm` — Multi-model LLM proxy (Groq, Gemini, OpenRouter)
- `homeassistant` — Home automation
- `n8n` — Workflow automation
- `glances` — System monitoring

---

### Node02 — Storage Node 📦
| Spec | Value |
|---|---|
| CPU | Intel i3 7th Gen — 4 threads |
| RAM | 8 GB |
| Storage | NVMe 238GB + 1TB USB |
| OS | Rocky Linux 10.1 (kernel 6.12) |
| Role | Self-hosted photo/video cloud storage |

**Running services:**
- `immich` — Self-hosted Google Photos alternative (server + ML + Redis + PostgreSQL)
- `dashy` — Homepage dashboard
- `portainer-agent` — Remote container management

---

### Node03 — Media Server 🎬
| Spec | Value |
|---|---|
| CPU | Intel i3 7th Gen — 4 threads |
| RAM | 8 GB |
| Storage | NVMe 238GB + 2x 1TB USB |
| OS | Rocky Linux 10.1 (kernel 6.12) |
| Role | Media streaming |

**Running services:**
- `jellyfin` — Self-hosted media server
- `glances` — System monitoring

---

## Tech Stack

### Infrastructure & Automation
| Tool | Purpose |
|---|---|
| **Ansible** | Configuration management, cluster automation |
| **Podman** | Rootless container runtime (on-premise nodes) |
| **Docker** | Container runtime (Oracle VPS) |
| **Tailscale** | Zero-trust mesh VPN across all nodes |

### AI / LLM Stack
| Tool | Purpose |
|---|---|
| **LiteLLM** | Unified proxy for multiple LLM providers |
| **Ollama** | Local LLM inference on Oracle ARM |
| **n8n** | AI workflow automation |
| **Groq API** | Fast LLM inference (Llama models) |
| **Gemini API** | Google AI models |
| **OpenRouter** | Multi-provider LLM routing |

### Monitoring
| Tool | Purpose |
|---|---|
| **Glances** | Per-node real-time system monitoring |
| **PCP (pmcd/pmlogger)** | Performance Co-Pilot on Rocky Linux nodes |

---

## Network Design

```
Home Network (LAN)
├── Node01  192.168.x.x
├── Node02  192.168.x.x
└── Node03  192.168.x.x

Tailscale Overlay Network (100.x.x.x range)
├── Node01  100.x.x.x
├── Node02  100.x.x.x
├── Node03  100.x.x.x
├── Node04  100.x.x.x (Oracle)
└── Personal devices (laptop, phone, tablet)

Security model:
- On-premise nodes: NOT exposed to internet
- All external access: via Tailscale only
- Oracle VPS: only public-facing node
```

---

## Repository Structure

```
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
│   ├── node01/                   # LiteLLM, n8n, HA compose files
│   ├── node02/                   # Immich stack
│   ├── node03/                   # Jellyfin
│   └── node04/                   # Oracle VPS services
│
├── docs/
│   └── architecture/             # Diagrams and design decisions
│
├── scripts/
│   ├── backup.sh                 # Automated backup via Tailscale
│   └── health-check.sh           # Cluster health check
│
├── .env.example                  # Template for environment variables
├── .gitignore                    # Excludes .env, inventory, secrets
└── README.md
```

---

## Security Practices

- **No secrets in repository** — all credentials via environment variables
- **Ansible Vault** — encrypted inventory and sensitive variables
- **Rootless Podman** — containers run without root privileges on-premise
- **Firewalld** — active on all Rocky Linux nodes
- **Zero open ports** — on-premise nodes accessible only via Tailscale
- **git-secrets** — pre-commit hook to prevent accidental credential leaks

---

## Skills Demonstrated

`Linux Administration` `Rocky Linux / RHEL` `Container Orchestration` `Ansible` `Podman` `Docker` `Networking` `Tailscale / WireGuard` `AI/LLM Integration` `LiteLLM` `n8n Automation` `Self-hosted Infrastructure` `Oracle Cloud` `System Monitoring` `Backup Strategies`

---

## Background

Electronic & Communication Engineering graduate (Politecnico di Torino).  
Currently pursuing MSc in Communication Engineering at PolTo / KIT Karlsruhe.  
Building this homelab to gain hands-on sysadmin and DevOps experience.

---

## What's Next

- [ ] Grafana + Prometheus + Loki — centralized monitoring stack
- [ ] Traefik — reverse proxy with automatic SSL on Oracle VPS
- [ ] Gitea + Woodpecker CI — self-hosted Git and CI/CD pipeline
- [ ] Headscale — self-hosted Tailscale coordination server
- [ ] k3s — Kubernetes learning cluster
- [ ] RHCSA certification preparation

---

*All IP addresses, hostnames, and credentials have been removed from this repository. See `.env.example` and `hosts.example.ini` for configuration templates.*
