# QGIS API Documentation Builder

A Nix-based build environment for generating and serving QGIS API documentation for all releases.

## Features

- Build API documentation for any QGIS release branch
- Multi-release documentation site with index page
- NixOS module for production deployment with nginx + Let's Encrypt
- Cachix integration for fast builds
- GitHub Actions for nightly updates

## Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- For deployment: NixOS server

## Quick Start

```bash
# Enter the development shell
nix develop

# Build master branch docs
nix build .#docs

# Serve documentation locally
nix run .#serve

# Build a specific release
nix run .#build-release -- release-3_34

# Assemble complete multi-release site
nix run .#assemble-docs -- ./my-docs-site
```

## Available Commands

| Command | Description |
|---------|-------------|
| `nix build .#docs` | Build master branch API documentation |
| `nix build .#index` | Build the index/landing page |
| `nix run .#serve` | Serve master docs at http://localhost:8080 |
| `nix run .#clean` | Clean build and output directories |
| `nix run .#build-release -- <branch>` | Build docs for a specific release |
| `nix run .#build-all-releases` | Build docs for all configured releases |
| `nix run .#assemble-docs` | Assemble complete documentation site |
| `nix run .#local-test` | Quick local test with placeholder docs |
| `nix run .#full-local-test` | Full local test with real documentation |

## Configured Releases

All QGIS releases are configured in `releases.nix`. The builder supports two build methods:

### Flake-based builds (modern releases)
Uses QGIS's native `flake.nix` for fast, cached builds. These are built nightly.

| Version | Branch | Type |
|---------|--------|------|
| master | master | Development (nightly) |
| 4.0 | release-4_0 | Latest |
| 3.44 | release-3_44 | Stable |
| 3.42 | release-3_42 | Stable |
| 3.40 | release-3_40 | LTS |

### Legacy builds (older releases)
Uses CMake/Doxygen directly for releases without `flake.nix`. Built manually via workflow.

<details>
<summary>Click to expand full legacy release list</summary>

| Version | Branch | Type |
|---------|--------|------|
| **QGIS 3.x** | | |
| 3.38 | release-3_38 | Stable |
| 3.36 | release-3_36 | Stable |
| 3.34 | release-3_34 | LTS |
| 3.32 | release-3_32 | Stable |
| 3.30 | release-3_30 | Stable |
| 3.28 | release-3_28 | LTS |
| 3.26 | release-3_26 | Stable |
| 3.24 | release-3_24 | Stable |
| 3.22 | release-3_22 | LTS |
| 3.20 | release-3_20 | Stable |
| 3.18 | release-3_18 | Stable |
| 3.16 | release-3_16 | LTS |
| 3.14 | release-3_14 | Stable |
| 3.12 | release-3_12 | Stable |
| 3.10 | release-3_10 | LTS |
| 3.8 | release-3_8 | Stable |
| 3.6 | release-3_6 | Stable |
| 3.4 | release-3_4 | LTS |
| 3.2 | release-3_2 | Stable |
| 3.0 | release-3_0 | Stable |
| **QGIS 2.x** | | |
| 2.18 | release-2_18 | LTS |
| 2.16 | release-2_16 | Stable |
| 2.14 | release-2_14 | LTS |
| 2.12 | release-2_12 | Stable |
| 2.10 | release-2_10 | Stable |
| 2.8 | release-2_8 | LTS |
| 2.6 | release-2_6 | Stable |
| 2.4 | release-2_4 | Stable |
| 2.0 | release-2_0 | Stable |
| **QGIS 1.x** | | |
| 1.8 | release-1_8 | Stable |
| 1.7 | release-1_7 | Stable |
| 1.6.0 | release-1_6_0 | Stable |
| 1.5.0 | release-1_5_0 | Stable |
| 1.4.0 | release-1_4_0 | Stable |
| 1.3.0 | release-1_3_0 | Stable |
| 1.2.0 | release-1_2_0 | Stable |
| 1.1.0 | release-1_1_0 | Stable |
| 1.0.0 | release-1_0_0 | Stable |
| **QGIS 0.x** | | |
| 0.11.0 | release-0_11_0 | Historical |
| 0.10.0 | release-0_10_0 | Historical |
| 0.9.1 | release-0_9_1 | Historical |
| 0.8.1 | release-0_8_1 | Historical |
| 0.8.0 | release-0_8_0 | Historical |
| 0.6 | release-0_6 | Historical |
| 0.5 | release-0_5 | Historical |
| 0.4 | release-0_4 | Historical |
| 0.3 | release-0_3 | Historical |
| 0.2 | release-0_2 | Historical |
| 0.1 | release-0_1 | Historical |

</details>

### Build commands

```bash
# Build all releases (flake + legacy)
./scripts/build-configured-releases.sh

# Skip legacy builds (faster, only flake-based)
SKIP_LEGACY=true ./scripts/build-configured-releases.sh

# Only build legacy releases
ONLY_LEGACY=true ./scripts/build-configured-releases.sh

# Build a single legacy release manually
nix run .#build-legacy-docs -- release-3_34 3.34
```

To add or remove releases, edit `releases.nix` and set `useLegacyBuild = true` for releases without flake.nix support.

## Multi-Release Site Assembly

Build a complete documentation site with all releases:

```bash
# Assemble all releases into a directory
nix run .#assemble-docs -- ./qgis-api-docs-site

# Serve the complete site
python -m http.server 8080 -d ./qgis-api-docs-site
```

This creates:

```
qgis-api-docs-site/
├── index.html      # Landing page with version selector
├── master/         # Development docs (with doxygen-awesome theme)
├── 3.44/           # Latest stable (with doxygen-awesome theme)
└── 3.40/           # Stable (with doxygen-awesome theme)
```

Each version directory contains the full API documentation styled with the [doxygen-awesome-css](https://jothepro.github.io/doxygen-awesome-css/) theme and QGIS custom branding.

## Local Testing

Test the documentation site locally without deploying.

### Quick Test (Placeholder Docs)

```bash
# Serves index page with placeholder version pages
nix run .#local-test
# Open http://localhost:8080
```

This starts instantly with placeholder pages for each version - useful for testing the index page layout and navigation.

### Full Test (Real Documentation)

```bash
# Assembles and serves actual documentation
nix run .#full-local-test
# Open http://localhost:8080
```

This builds/downloads real Doxygen documentation for each release. Slow on first run, but cached in `./qgis-api-docs-local-test/` for subsequent runs.

### Custom Port

```bash
PORT=3000 nix run .#local-test
```

## NixOS Deployment

Deploy the documentation site with nginx and Let's Encrypt SSL.

### Quick Deployment

```nix
# In your NixOS configuration
{
  imports = [
    (builtins.getFlake "github:qgis/qgis-api-docs-builder").nixosModules.qgis-api-docs
  ];

  services.qgis-api-docs = {
    enable = true;
    domain = "api.qgis.org";
    docsPath = "/var/www/qgis-api-docs";
    enableACME = true;
    acmeEmail = "admin@example.com";
  };
}
```

### Module Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable the service |
| `domain` | string | required | Domain name for the site |
| `docsPath` | path | required | Path to documentation files |
| `enableACME` | bool | `true` | Enable Let's Encrypt SSL |
| `acmeEmail` | string | required | Email for Let's Encrypt |
| `openFirewall` | bool | `true` | Open ports 80 and 443 |
| `extraNginxConfig` | string | `""` | Additional nginx configuration |

### Using the Deployment Template

```bash
# Initialize from template
nix flake init -t github:qgis/qgis-api-docs-builder#deployment

# Edit configuration
vim flake.nix

# Deploy
nixos-rebuild switch --flake .#qgis-api-docs-server
```

## Cachix Binary Cache

Speed up builds with Cachix.

### Using the Cache

```bash
cachix use qgisapidocumentation
```

### Setting Up Your Own Cache

1. Create account at [app.cachix.org](https://app.cachix.org/)
2. Create a new cache
3. Get your auth token
4. Configure:

```bash
cachix authtoken <YOUR_TOKEN>
export CACHIX_AUTH_TOKEN=<YOUR_TOKEN>
```

See the [Cachix documentation](#cachix-binary-cache-1) below for full details.

## GitHub Actions

### Workflows

| Workflow | Schedule | Description |
|----------|----------|-------------|
| **Detect New Releases** | Daily 4am UTC | Detect new QGIS releases, update `releases.nix`, trigger builds |
| **Nightly** | Daily 3am UTC | Build flake-based releases (3.40+), push to Cachix |

> **Note:** Additional workflows for one-time operations (build-all-releases, build-legacy-releases, build-single-release) are archived in `.github/workflows/archive/` for reference.

### Required Secrets

| Secret | Description |
|--------|-------------|
| `CACHIX_AUTH_TOKEN` | Cachix authentication token for pushing builds |

### Setting Up Cachix for GitHub Actions

To enable CI builds to push to Cachix, follow these steps:

#### 1. Create a Cachix Account and Cache

1. Go to [app.cachix.org](https://app.cachix.org/) and sign up
2. Click **Create Cache**
3. Name your cache (e.g., `qgis-api-docs`)
4. Choose **Public** for open source projects
5. Click **Create**

#### 2. Generate an Auth Token

1. Go to [Personal Auth Tokens](https://app.cachix.org/personal-auth-tokens)
2. Click **Generate Token**
3. Give it a descriptive name (e.g., `github-actions-qgis-api-docs`)
4. Select permissions:
   - **Read** - to pull cached artifacts
   - **Write** - to push new builds
5. Click **Generate**
6. **Copy the token immediately** - it won't be shown again

#### 3. Add Secret to GitHub Repository

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `CACHIX_AUTH_TOKEN`
5. Value: Paste the token from step 2
6. Click **Add secret**

#### 4. Update Cache Name (if different)

If your cache is not named `qgis-api-docs`, update the workflows:

```yaml
# In .github/workflows/nightly.yml and detect-new-releases.yml
env:
  CACHIX_CACHE: your-cache-name
```

#### 5. Verify Setup

1. Manually trigger the **Nightly Docs Build** workflow:
   - Go to **Actions** → **Nightly Docs Build** → **Run workflow**
2. Check the workflow logs for successful Cachix push
3. Verify artifacts appear at `https://your-cache-name.cachix.org`

### Workflow Details

#### Detect New Releases (`detect-new-releases.yml`)

Runs daily at 4am UTC to:
1. Scan QGIS GitHub for new release branches (e.g., `release-3_46`)
2. Check if the branch has `flake.nix` support
3. Add new releases to `releases.nix`
4. Commit and push changes
5. Trigger the nightly workflow to build docs

#### Nightly Build (`nightly.yml`)

Runs daily at 3am UTC (or when triggered) to:
1. Build the index/landing page
2. Build API docs for each release in `releases.nix`
3. Apply doxygen-awesome theme to all HTML files
4. Push built artifacts to Cachix

## Build Options

### build-all-releases

```
Usage: build-all-releases [OPTIONS]

Options:
  -c, --cache NAME      Cachix cache name (default: qgis-api-docs)
  -j, --jobs N          Number of parallel builds (default: 1)
  -m, --min-version V   Minimum version to build (default: 2.0)
  -r, --release NAME    Build only this specific release
  -n, --dry-run         Show what would be built without building
  -h, --help            Show help message

Environment Variables:
  CACHIX_CACHE          Cachix cache name
  CACHIX_AUTH_TOKEN     Cachix authentication token
```

### build-release

```bash
# Build a specific release
nix run .#build-release -- release-3_34

# Build master
nix run .#build-release -- master
```

## Directory Structure

```
QGIS-API-Docs-Builder/
├── flake.nix              # Main Nix flake configuration
├── flake.lock             # Locked dependency versions
├── releases.nix           # Release definitions (auto-updated by CI)
├── .envrc                 # direnv configuration
├── README.md              # This file
├── templates/
│   ├── index.html         # Landing page template
│   └── deployment/        # NixOS deployment template
│       ├── flake.nix
│       └── README.md
├── theme/
│   ├── doxygen-awesome.css              # Base doxygen-awesome theme
│   ├── doxygen-awesome-sidebar-only.css # Sidebar variant
│   ├── doxygen-awesome-darkmode-toggle.css
│   ├── doxygen-awesome-darkmode-toggle.js
│   └── qgis-theme.css                   # QGIS-specific customizations
├── scripts/
│   ├── build-configured-releases.sh     # Build all releases with theme
│   ├── build-all-releases.sh
│   ├── build-release.sh
│   └── setup-cachix.sh
└── .github/
    └── workflows/
        ├── detect-new-releases.yml      # Auto-detect new QGIS releases
        ├── nightly.yml                  # Build flake-based docs nightly
        └── archive/                     # One-time build workflows (reference)
            ├── build-all-releases.yml
            ├── build-legacy-releases.yml
            └── build-single-release.yml
```

## Cachix Binary Cache

This project uses [Cachix](https://cachix.org) to cache build artifacts.

### Using the binary cache (end users)

```bash
# Add the binary cache
cachix use qgisapidocumentation
```

Or add to `~/.config/nix/nix.conf`:

```ini
substituters = https://cache.nixos.org https://qgisapidocumentation.cachix.org
trusted-public-keys = cache.nixos.org-1:... qgisapidocumentation.cachix.org-1:YOUR_KEY
```

### Setting up Cachix (maintainers)

1. Create account at [app.cachix.org](https://app.cachix.org/)
2. Create a new cache
3. Get credentials:
   - Auth token: [Personal Auth Tokens](https://app.cachix.org/personal-auth-tokens)
   - Public key: Cache settings page

4. Configure locally:

```bash
cachix authtoken <YOUR_TOKEN>
export CACHIX_AUTH_TOKEN=<YOUR_TOKEN>
```

5. Push builds:

```bash
# Builds automatically push when CACHIX_AUTH_TOKEN is set
nix run .#build-release -- release-3_34
```

### GitHub Actions

Add `CACHIX_AUTH_TOKEN` as a repository secret. Workflows automatically push successful builds to Cachix.

## Troubleshooting

### "Documentation not available for this branch"

The QGIS branch may not have Nix flake support. Only QGIS 3.22+ branches have proper flake support.

### "Binary cache doesn't exist"

- Check your cache name is correct
- Ensure `CACHIX_AUTH_TOKEN` is set
- Verify the token hasn't expired

### Build takes too long

Building QGIS documentation from source requires building QGIS dependencies. Use Cachix to cache builds.

---

Made with 💗 by [Kartoza](https://kartoza.com) | [Donate!](https://qgis.org/funding/donate/) | [GitHub](https://github.com/qgis/qgis-api-docs-builder)
