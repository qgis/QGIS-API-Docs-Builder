# QGIS API Documentation Server Deployment

This template provides a NixOS configuration for deploying the QGIS API documentation site with:

- Nginx web server
- Let's Encrypt SSL certificates (certbot/ACME)
- Automatic nightly documentation updates
- All QGIS release documentation

## Quick Start

1. Copy this template to your server configuration:

```bash
nix flake init -t github:qgis/qgis-api-docs-builder#deployment
```

2. Edit `flake.nix` and update:
   - `domain` - Your domain name
   - `acmeEmail` - Your email for Let's Encrypt

3. Deploy to your server:

```bash
nixos-rebuild switch --flake .#qgis-api-docs-server
```

## Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `enable` | Enable the service | `false` |
| `domain` | Domain name for the site | required |
| `docsPath` | Path to documentation files | required |
| `enableACME` | Enable Let's Encrypt SSL | `true` |
| `acmeEmail` | Email for Let's Encrypt | required if ACME enabled |
| `openFirewall` | Open ports 80 and 443 | `true` |
| `extraNginxConfig` | Additional nginx config | `""` |

## Manual Documentation Update

```bash
# SSH into your server
sudo systemctl start qgis-api-docs-update
```

## Directory Structure

After deployment:

```
/var/www/qgis-api-docs/
├── index.html          # Landing page with version selector
├── master/             # Development docs (updated nightly)
├── 3.40/               # Latest stable
├── 3.38/               # Previous stable
├── 3.34/               # LTS release
├── 3.28/               # Previous LTS
└── 3.22/               # Older LTS
```

---

Made with 💗 by [Kartoza](https://kartoza.com)
