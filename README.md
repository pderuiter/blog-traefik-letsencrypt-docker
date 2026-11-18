# blog-traefik-letsencrypt-docker

Companion code for the blog post
[Configuring Traefik with Let's Encrypt on Docker](https://webuildyourcloud.com/configuring-traefik-with-lets-encrypt-on-docker/).

It builds the setup from the post. It creates an Ubuntu 24.04 VM, installs Docker CE with the Compose plugin, and runs
Traefik v2.11 with:
- Let's Encrypt certificates over a DNS-01 challenge at TransIP.
- The dashboard on its own host name, behind basic auth.
- Prometheus metrics on the `web` entrypoint.

## What's in here

| Path | What it does |
| --- | --- |
| `terraform/` | One Proxmox VE VM from the Ubuntu 24.04 cloud image (bpg/proxmox provider). Outputs an Ansible inventory. |
| `ansible/roles/docker_engine` | Docker CE, containerd and the Compose v2 plugin from download.docker.com. |
| `ansible/roles/traefik` | The post, step by step. It creates `traefik-docker/config/`, creates `acme.json` with mode 600, and writes `config/traefik.yml` and `docker-compose.yml`. The dashboard password is hashed in `htpasswd` apr1 format, with every `$` doubled for Compose. Then it starts Traefik. |
| `ansible/site.yml` | Runs both roles against the `traefik` group. |

## Requirements

- Terraform >= 1.6 and a Proxmox VE API token (only if you want Terraform to create the VM).
- Ansible >= 2.16 (ansible-core) and the collections in `ansible/requirements.yml`.
- SSH access with sudo to the machine. The Terraform cloud-init user is `ubuntu`.
- A domain at TransIP and a TransIP API key pair. lego's TransIP provider authenticates with the account name and the
  API **private key** (`TRANSIP_ACCOUNT_NAME` and `TRANSIP_PRIVATE_KEY_PATH`). The role writes the key to
  `config/transip.key` and mounts it as `/transip.key`.
- A DNS record for the dashboard host (`traefik.yourdomain.com`) pointing at the VM.

## Quick start

```bash
# 1. Machine (optional; any Ubuntu 24.04 host works)
cd terraform
cp terraform.tfvars.example terraform.tfvars   # fill in endpoint, token, node, IP, SSH key
terraform init
terraform apply
terraform output -raw ansible_inventory > ../ansible/inventory.yml

# 2. Configuration
cd ../ansible
ansible-galaxy collection install -r requirements.yml
$EDITOR group_vars/all/vars.yml                  # e-mail, dashboard host, TransIP account name
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
ansible-vault encrypt group_vars/all/vault.yml   # dashboard password, TransIP private key
ansible-playbook site.yml --ask-vault-pass
```

Without Terraform, copy `ansible/inventory.example.yml` to `ansible/inventory.yml` and put your host in the `traefik` group.

Check that the certificate was issued with `docker logs traefik`. Then open `https://traefik.yourdomain.com`.

## Variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `traefik_image` | `traefik:v2.11` | v2.11 or later; older v2 images can't talk to Docker Engine 29 |
| `traefik_acme_email` | `your_email@example.com` | ACME account e-mail |
| `traefik_acme_ca_server` | empty (Let's Encrypt production) | Set to `https://acme-staging-v02.api.letsencrypt.org/directory` while testing |
| `traefik_cert_resolver` | `transip` | Name of the certificate resolver |
| `traefik_dns_provider` | `transip` | lego DNS provider |
| `traefik_dns_provider_env` | TransIP account name + key path | Environment for the DNS provider |
| `traefik_transip_private_key` | from the vault | TransIP API private key (PEM) |
| `traefik_dns_delay_before_check` | `0` | `dnsChallenge.delayBeforeCheck` |
| `traefik_dashboard_host` | `traefik.yourdomain.com` | Host rule for the dashboard router |
| `traefik_dashboard_user` / `traefik_dashboard_password` | `admin` / from the vault | Basic auth for the dashboard |
| `traefik_log_level` | `DEBUG` | As in the post. `INFO` is quieter |
| `traefik_dir` | `/opt/traefik-docker` | Project directory on the host |
| `traefik_network` | `traefik-network` | Docker network that other containers join to be routed |
| `traefik_extra_volumes` / `traefik_extra_hosts` | `[]` | Extra bind mounts and `/etc/hosts` entries for the container |

Another DNS provider works the same way: set `traefik_dns_provider` to its lego name and put its variables in
`traefik_dns_provider_env`.

## Tested

`site.yml` was run against a fresh Ubuntu 24.04 systemd container (Docker 29, Compose v2). The second run reported
`changed=0`. Pebble stood in for Let's Encrypt, using `traefik_acme_ca_server`, lego's `exec` provider and
`pebble-challtestsrv` for DNS. With that:
- The dashboard returned 401 without credentials, 401 with a wrong password, and 200 with the right one.
- The certificate served for `traefik.lab.test` was issued by the Pebble CA.
- `/metrics` on port 80 served the `traefik_*` series.

A run with the TransIP provider confirmed that lego needs `TRANSIP_PRIVATE_KEY_PATH`. With only an API key variable,
Traefik logs `transip: some credentials information are missing: TRANSIP_PRIVATE_KEY_PATH`. Real TransIP and Let's
Encrypt were not used.

ansible-lint (production profile), yamllint, `terraform validate` and tflint are clean. The Terraform code has not been
applied against a real Proxmox cluster.

## License

MIT
