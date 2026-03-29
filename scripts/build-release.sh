#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# QGIS API Documentation Builder - Build Single Release
# ═══════════════════════════════════════════════════════════════════════════════
#
# Builds API documentation for a specific QGIS release branch
#
# Made with 💗 by Kartoza | https://kartoza.com
#
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

BRANCH="${1:-}"
CACHIX_CACHE="${CACHIX_CACHE:-qgis-api-docs}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

if [[ -z "$BRANCH" ]]; then
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║           QGIS API Documentation - Build Single Release           ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Usage: build-release <branch-name>"
    echo ""
    echo "Examples:"
    echo "  build-release release-3_34"
    echo "  build-release release-3_28"
    echo "  build-release master"
    echo ""
    echo "Environment Variables:"
    echo "  CACHIX_CACHE          Cachix cache name (default: qgis-api-docs)"
    echo "  CACHIX_AUTH_TOKEN     Cachix authentication token"
    echo ""
    echo "Made with 💗 by Kartoza | https://kartoza.com"
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║           QGIS API Documentation - Build Single Release           ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Building QGIS API docs for $BRANCH..."

# Create temporary flake
TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

# Generate flake.nix content
# Note: We use a simple approach that just references the docs package
# If the QGIS flake doesn't have docs for older branches, nix will error
cat > "$TEMP_DIR/flake.nix" << 'FLAKE_TEMPLATE'
{
  description = "QGIS API Documentation for BRANCH_PLACEHOLDER";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    qgis = {
      url = "github:qgis/QGIS/BRANCH_PLACEHOLDER";
      flake = true;
    };
  };

  outputs = { self, nixpkgs, flake-utils, qgis }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        # Try to get docs from the QGIS flake
        # Older branches may not have the docs package
        qgisDocs = qgis.packages.${system}.docs or null;
      in {
        packages = {
          docs = if qgisDocs != null
            then qgisDocs
            else throw "Documentation not available for this QGIS branch. The branch may be too old to have Nix flake support.";
          default = self.packages.${system}.docs;
        };
      }
    );
}
FLAKE_TEMPLATE

# Replace placeholder with actual branch name
sed -i "s/BRANCH_PLACEHOLDER/$BRANCH/g" "$TEMP_DIR/flake.nix"

log_info "Created temporary flake at $TEMP_DIR"

# Build
log_info "Building documentation (this may take a while)..."
if OUT_PATH=$(nix build "$TEMP_DIR#docs" --no-link --print-out-paths 2>&1); then
    log_success "Built: $OUT_PATH"

    # Show some stats
    if [[ -d "$OUT_PATH" ]]; then
        FILE_COUNT=$(find "$OUT_PATH" -type f 2>/dev/null | wc -l)
        SIZE=$(du -sh "$OUT_PATH" 2>/dev/null | cut -f1)
        echo ""
        log_info "Documentation stats:"
        echo "  Files: $FILE_COUNT"
        echo "  Size:  $SIZE"
    fi

    # Push to cachix if token available
    if [[ -n "${CACHIX_AUTH_TOKEN:-}" ]]; then
        echo ""
        log_info "Pushing to cachix ($CACHIX_CACHE)..."
        echo "$OUT_PATH" | cachix push "$CACHIX_CACHE"
        log_success "Pushed successfully!"
    else
        echo ""
        log_info "CACHIX_AUTH_TOKEN not set, skipping push"
    fi

    echo ""
    log_success "Done! Documentation built for $BRANCH"
    echo ""
    echo "To serve locally:"
    echo "  python -m http.server 8080 -d $OUT_PATH"
    echo ""
else
    log_error "Build failed for $BRANCH"
    echo "$OUT_PATH"
    exit 1
fi
