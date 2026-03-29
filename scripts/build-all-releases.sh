#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# QGIS API Documentation Builder - Multi-Release Builder
# ═══════════════════════════════════════════════════════════════════════════════
#
# Iterates over all QGIS release branches, builds API documentation for each,
# and publishes to cachix.org
#
# Made with 💗 by Kartoza | https://kartoza.com
#
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────
QGIS_REPO="https://github.com/qgis/QGIS.git"
CACHIX_CACHE="${CACHIX_CACHE:-qgis-api-docs}"
PARALLEL_JOBS="${PARALLEL_JOBS:-1}"
MIN_VERSION="${MIN_VERSION:-2.0}"  # Skip versions older than this
DRY_RUN="${DRY_RUN:-false}"
SPECIFIC_RELEASE="${SPECIFIC_RELEASE:-}"  # Build only this release if set
# Use PWD for logs so it works from any directory
BUILD_LOG_DIR="${BUILD_LOG_DIR:-${PWD}/qgis-api-docs-build-logs}"
FAILED_BUILDS_FILE="${BUILD_LOG_DIR}/failed-builds.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

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

log_section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $*${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

show_banner() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║           QGIS API Documentation - Multi-Release Builder                      ║"
    echo "║                                                                               ║"
    echo "║   Builds API documentation for all QGIS releases and publishes to Cachix     ║"
    echo "║                                                                               ║"
    echo "║   Made with 💗 by Kartoza | https://kartoza.com                               ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
}

show_usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -c, --cache NAME      Cachix cache name (default: $CACHIX_CACHE)
  -j, --jobs N          Number of parallel builds (default: $PARALLEL_JOBS)
  -m, --min-version V   Minimum version to build (default: $MIN_VERSION)
  -r, --release NAME    Build only this specific release (e.g., release-3_34)
  -n, --dry-run         Show what would be built without building
  -h, --help            Show this help message

Environment Variables:
  CACHIX_CACHE          Cachix cache name
  CACHIX_AUTH_TOKEN     Cachix authentication token (required for push)
  PARALLEL_JOBS         Number of parallel builds
  MIN_VERSION           Minimum version to build
  SPECIFIC_RELEASE      Build only this specific release
  DRY_RUN               Set to 'true' for dry run

Examples:
  # Build all releases >= 2.0 and push to cachix
  $(basename "$0")

  # Build only 3.x releases
  $(basename "$0") --min-version 3.0

  # Build a specific release
  $(basename "$0") --release release-3_34

  # Dry run - show what would be built
  $(basename "$0") --dry-run

EOF
}

# Parse version string (e.g., "release-3_34" -> "3.34")
parse_version() {
    local branch="$1"
    # Extract version from branch name: release-3_34 -> 3.34
    echo "$branch" | sed -E 's/^release-([0-9]+)_([0-9]+)$/\1.\2/' | sed -E 's/^release-([0-9]+)\.([0-9]+)$/\1.\2/'
}

# Compare versions (returns 0 if $1 >= $2)
version_ge() {
    local v1="$1"
    local v2="$2"

    # Handle non-numeric versions
    if ! [[ "$v1" =~ ^[0-9]+\.[0-9]+$ ]]; then
        return 1
    fi

    local v1_major v1_minor v2_major v2_minor
    v1_major=$(echo "$v1" | cut -d. -f1)
    v1_minor=$(echo "$v1" | cut -d. -f2)
    v2_major=$(echo "$v2" | cut -d. -f1)
    v2_minor=$(echo "$v2" | cut -d. -f2)

    if [[ "$v1_major" -gt "$v2_major" ]]; then
        return 0
    elif [[ "$v1_major" -eq "$v2_major" ]] && [[ "$v1_minor" -ge "$v2_minor" ]]; then
        return 0
    fi
    return 1
}

# Check if cachix is available and authenticated
check_cachix() {
    if ! command -v cachix &> /dev/null; then
        log_error "cachix is not installed. Please install it first:"
        echo "  nix-env -iA cachix -f https://cachix.org/api/v1/install"
        echo "  OR"
        echo "  nix profile install nixpkgs#cachix"
        return 1
    fi

    if [[ -z "${CACHIX_AUTH_TOKEN:-}" ]]; then
        log_warn "CACHIX_AUTH_TOKEN is not set. Will build but not push to cachix."
        return 0
    fi

    log_info "Cachix is configured for cache: $CACHIX_CACHE"
    return 0
}

# Fetch all release branches from QGIS repository
fetch_release_branches() {
    log_info "Fetching release branches from QGIS repository..."

    # Use git ls-remote to fetch branches without cloning
    local branches
    branches=$(git ls-remote --heads "$QGIS_REPO" 2>/dev/null | \
        awk '{print $2}' | \
        sed 's|refs/heads/||' | \
        grep '^release-' | \
        sort -V)

    if [[ -z "$branches" ]]; then
        log_error "No release branches found!"
        return 1
    fi

    echo "$branches"
}

# Filter branches by minimum version
filter_branches() {
    local branches="$1"
    local filtered=""

    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue

        local version
        version=$(parse_version "$branch")

        if version_ge "$version" "$MIN_VERSION"; then
            filtered="${filtered}${branch}"$'\n'
        else
            log_info "Skipping $branch (version $version < $MIN_VERSION)"
        fi
    done <<< "$branches"

    echo "$filtered" | grep -v '^$' || true
}

# Build docs for a specific branch
build_release_docs() {
    local branch="$1"
    local version
    version=$(parse_version "$branch")
    local log_file="${BUILD_LOG_DIR}/${branch}.log"

    log_section "Building documentation for $branch (version $version)"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would build: $branch"
        return 0
    fi

    # Create a temporary flake that references the specific branch
    local temp_dir
    temp_dir=$(mktemp -d)
    cleanup() { rm -rf "$temp_dir"; }
    trap cleanup EXIT

    cat > "$temp_dir/flake.nix" <<EOF
{
  description = "QGIS API Documentation for $branch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    qgis = {
      url = "github:qgis/QGIS/$branch";
      flake = true;
    };
  };

  outputs = { self, nixpkgs, flake-utils, qgis }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        # Try to get docs from the QGIS flake, fall back to null if not available
        qgisDocs = qgis.packages.\${system}.docs or null;
      in
      {
        packages = {
          docs = if qgisDocs != null
            then qgisDocs
            else pkgs.runCommand "qgis-docs-unavailable-$branch" {} ''
              mkdir -p \$out
              echo "Documentation not available for $branch" > \$out/index.html
            '';
          default = self.packages.\${system}.docs;
        };
      }
    );
}
EOF

    log_info "Building documentation in temporary flake..."

    # Build the docs
    local build_start
    build_start=$(date +%s)

    if nix build "$temp_dir#docs" --no-link --print-out-paths 2>&1 | tee "$log_file"; then
        local build_end
        build_end=$(date +%s)
        local duration=$((build_end - build_start))
        log_success "Built $branch in ${duration}s"

        # Get the output path
        local out_path
        out_path=$(nix build "$temp_dir#docs" --no-link --print-out-paths 2>/dev/null)

        if [[ -n "$out_path" ]] && [[ -d "$out_path" ]]; then
            # Push to cachix if token is available
            if [[ -n "${CACHIX_AUTH_TOKEN:-}" ]]; then
                log_info "Pushing $branch to cachix ($CACHIX_CACHE)..."
                echo "$out_path" | cachix push "$CACHIX_CACHE" 2>&1 | tee -a "$log_file"
                log_success "Pushed $branch to cachix"
            else
                log_warn "Skipping cachix push (no CACHIX_AUTH_TOKEN)"
            fi
        fi

        return 0
    else
        log_error "Failed to build $branch (see $log_file)"
        echo "$branch" >> "$FAILED_BUILDS_FILE"
        return 1
    fi
}

# Build using the project's flake with branch override
build_release_docs_native() {
    local branch="$1"
    local version
    version=$(parse_version "$branch")
    local log_file="${BUILD_LOG_DIR}/${branch}.log"

    log_section "Building documentation for $branch (version $version)"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would build: $branch"
        return 0
    fi

    log_info "Building documentation with branch override..."

    # Build the docs with the specific branch
    local build_start
    build_start=$(date +%s)

    # Use nix build with --override-input to point to the specific branch
    local build_cmd="nix build ${PROJECT_ROOT}#docs-${branch} --no-link --print-out-paths"

    if eval "$build_cmd" 2>&1 | tee "$log_file"; then
        local build_end
        build_end=$(date +%s)
        local duration=$((build_end - build_start))
        log_success "Built $branch in ${duration}s"

        # Get the output path
        local out_path
        out_path=$(eval "$build_cmd" 2>/dev/null || true)

        if [[ -n "$out_path" ]] && [[ -d "$out_path" ]]; then
            # Push to cachix if token is available
            if [[ -n "${CACHIX_AUTH_TOKEN:-}" ]]; then
                log_info "Pushing $branch to cachix ($CACHIX_CACHE)..."
                echo "$out_path" | cachix push "$CACHIX_CACHE" 2>&1 | tee -a "$log_file"
                log_success "Pushed $branch to cachix"
            else
                log_warn "Skipping cachix push (no CACHIX_AUTH_TOKEN)"
            fi
        fi

        return 0
    else
        log_error "Failed to build $branch (see $log_file)"
        echo "$branch" >> "$FAILED_BUILDS_FILE"
        return 1
    fi
}

# Main build process
main() {
    show_banner

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--cache)
                CACHIX_CACHE="$2"
                shift 2
                ;;
            -j|--jobs)
                PARALLEL_JOBS="$2"
                shift 2
                ;;
            -m|--min-version)
                MIN_VERSION="$2"
                shift 2
                ;;
            -r|--release)
                SPECIFIC_RELEASE="$2"
                shift 2
                ;;
            -n|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Create log directory
    mkdir -p "$BUILD_LOG_DIR"
    rm -f "$FAILED_BUILDS_FILE"

    # Check prerequisites
    check_cachix || exit 1

    # Get branches to build
    local branches
    if [[ -n "$SPECIFIC_RELEASE" ]]; then
        branches="$SPECIFIC_RELEASE"
        log_info "Building specific release: $SPECIFIC_RELEASE"
    else
        branches=$(fetch_release_branches)
        branches=$(filter_branches "$branches")
    fi

    if [[ -z "$branches" ]]; then
        log_error "No branches to build!"
        exit 1
    fi

    # Count branches
    local branch_count
    branch_count=$(echo "$branches" | wc -l)
    log_info "Found $branch_count release branches to build"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No actual builds will be performed"
    fi

    # Build each release
    local success_count=0
    local fail_count=0

    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue

        if build_release_docs "$branch"; then
            ((success_count++)) || true
        else
            ((fail_count++)) || true
        fi
    done <<< "$branches"

    # Summary
    log_section "Build Summary"
    echo "  Total releases:    $branch_count"
    echo "  Successful builds: $success_count"
    echo "  Failed builds:     $fail_count"

    if [[ -f "$FAILED_BUILDS_FILE" ]]; then
        echo ""
        echo "  Failed releases:"
        while IFS= read -r failed; do
            echo "    - $failed"
        done < "$FAILED_BUILDS_FILE"
    fi

    echo ""
    log_info "Build logs are available in: $BUILD_LOG_DIR"

    if [[ "$fail_count" -gt 0 ]]; then
        exit 1
    fi

    log_success "All builds completed successfully!"
}

main "$@"
