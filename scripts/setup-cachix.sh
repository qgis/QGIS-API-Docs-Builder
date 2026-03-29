#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# QGIS API Documentation Builder - Cachix Setup Script
# ═══════════════════════════════════════════════════════════════════════════════
#
# Sets up Cachix binary cache for faster builds and distribution
#
# Made with 💗 by Kartoza | https://kartoza.com
#
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

CACHIX_CACHE="${CACHIX_CACHE:-qgis-api-docs}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

show_banner() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║           QGIS API Documentation - Cachix Setup                               ║"
    echo "║                                                                               ║"
    echo "║   Made with 💗 by Kartoza | https://kartoza.com                               ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
}

check_nix() {
    if ! command -v nix &> /dev/null; then
        log_error "Nix is not installed. Please install Nix first:"
        echo "  curl -L https://nixos.org/nix/install | sh"
        exit 1
    fi
    log_success "Nix is installed"
}

install_cachix() {
    if command -v cachix &> /dev/null; then
        log_success "Cachix is already installed"
        return 0
    fi

    log_info "Installing Cachix..."
    if nix profile install nixpkgs#cachix 2>/dev/null || nix-env -iA cachix -f https://cachix.org/api/v1/install 2>/dev/null; then
        log_success "Cachix installed successfully"
    else
        log_error "Failed to install Cachix"
        exit 1
    fi
}

create_cache() {
    log_info "Creating Cachix cache '$CACHIX_CACHE'..."
    echo ""
    echo "To create a new cache, you need to:"
    echo ""
    echo "1. Create a Cachix account at: https://app.cachix.org/"
    echo ""
    echo "2. Create a new cache named '$CACHIX_CACHE' at:"
    echo "   https://app.cachix.org/cache"
    echo ""
    echo "3. Get your auth token from:"
    echo "   https://app.cachix.org/personal-auth-tokens"
    echo ""
    echo "4. Authenticate cachix locally:"
    echo "   cachix authtoken <YOUR_TOKEN>"
    echo ""
    echo "5. Set the token for CI/scripts:"
    echo "   export CACHIX_AUTH_TOKEN=<YOUR_TOKEN>"
    echo ""
}

configure_binary_cache() {
    log_info "Configuring Nix to use the '$CACHIX_CACHE' binary cache..."

    if [[ -f ~/.config/nix/nix.conf ]]; then
        if grep -q "$CACHIX_CACHE.cachix.org" ~/.config/nix/nix.conf; then
            log_success "Binary cache already configured in nix.conf"
            return 0
        fi
    fi

    echo ""
    echo "To use the binary cache, add this to your ~/.config/nix/nix.conf:"
    echo ""
    echo "  substituters = https://cache.nixos.org https://$CACHIX_CACHE.cachix.org"
    echo "  trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= $CACHIX_CACHE.cachix.org-1:PLACEHOLDER_KEY"
    echo ""
    echo "Or run: cachix use $CACHIX_CACHE"
    echo ""
}

show_github_actions_setup() {
    echo ""
    log_info "GitHub Actions Setup"
    echo ""
    echo "Add these secrets to your repository:"
    echo "  - CACHIX_AUTH_TOKEN: Your Cachix auth token"
    echo ""
    echo "The workflow file is at: .github/workflows/build-all-releases.yml"
    echo ""
}

main() {
    show_banner

    case "${1:-setup}" in
        setup)
            check_nix
            install_cachix
            create_cache
            configure_binary_cache
            show_github_actions_setup
            log_success "Setup complete! Follow the instructions above to finish configuration."
            ;;
        use)
            log_info "Configuring Nix to use $CACHIX_CACHE binary cache..."
            cachix use "$CACHIX_CACHE"
            log_success "Binary cache configured!"
            ;;
        push)
            if [[ -z "${2:-}" ]]; then
                log_error "Usage: $0 push <store-path>"
                exit 1
            fi
            log_info "Pushing to $CACHIX_CACHE..."
            echo "$2" | cachix push "$CACHIX_CACHE"
            log_success "Pushed successfully!"
            ;;
        *)
            echo "Usage: $0 [setup|use|push <path>]"
            echo ""
            echo "Commands:"
            echo "  setup     - Set up Cachix (default)"
            echo "  use       - Configure Nix to use the binary cache"
            echo "  push      - Push a store path to the cache"
            exit 1
            ;;
    esac
}

main "$@"
