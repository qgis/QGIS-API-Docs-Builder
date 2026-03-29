#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# QGIS API Documentation - Apply Custom Theme
# ═══════════════════════════════════════════════════════════════════════════════
#
# Applies doxygen-awesome-css and QGIS custom theme to built documentation
#
# Made with 💗 by Kartoza | https://kartoza.com
#
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
THEME_DIR="$PROJECT_DIR/theme"
DOCS_DIR="${1:-$PROJECT_DIR/docs-output}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║           QGIS API Documentation - Apply Theme                    ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

if [[ ! -d "$DOCS_DIR" ]]; then
    echo "Error: Docs directory not found: $DOCS_DIR"
    exit 1
fi

# Find all version directories (excluding index.html)
for version_dir in "$DOCS_DIR"/*/; do
    [[ ! -d "$version_dir" ]] && continue
    version=$(basename "$version_dir")

    log_info "Applying theme to $version..."

    # Find the actual docs directory (might be nested under 'master')
    if [[ -d "$version_dir/master" ]]; then
        docs_path="$version_dir/master"
    else
        docs_path="$version_dir"
    fi

    # Check if this looks like doxygen output
    if [[ ! -f "$docs_path/index.html" ]]; then
        echo "  Skipping $version - no index.html found"
        continue
    fi

    # Copy theme CSS files
    cp "$THEME_DIR/doxygen-awesome.css" "$docs_path/"
    cp "$THEME_DIR/doxygen-awesome-sidebar-only.css" "$docs_path/"
    cp "$THEME_DIR/doxygen-awesome-sidebar-only-darkmode-toggle.css" "$docs_path/"
    cp "$THEME_DIR/doxygen-awesome-darkmode-toggle.js" "$docs_path/"
    cp "$THEME_DIR/qgis-theme.css" "$docs_path/"

    # Inject CSS links into all HTML files
    log_info "  Injecting CSS into HTML files..."

    # CSS to inject (after existing stylesheets)
    CSS_INJECT='<link rel="stylesheet" href="doxygen-awesome.css"/>\n<link rel="stylesheet" href="doxygen-awesome-sidebar-only.css"/>\n<link rel="stylesheet" href="doxygen-awesome-sidebar-only-darkmode-toggle.css"/>\n<link rel="stylesheet" href="qgis-theme.css"/>\n<script src="doxygen-awesome-darkmode-toggle.js"></script>'

    # Find and update HTML files
    find "$docs_path" -name "*.html" -type f | while read -r html_file; do
        # Check if already has our theme
        if grep -q "doxygen-awesome.css" "$html_file" 2>/dev/null; then
            continue
        fi

        # Inject after the last existing stylesheet link or before </head>
        if grep -q '</head>' "$html_file" 2>/dev/null; then
            sed -i "s|</head>|${CSS_INJECT}\n</head>|" "$html_file"
        fi
    done

    log_success "  Theme applied to $version"
done

echo ""
log_success "Theme applied to all versions!"
echo ""
echo "To view: python -m http.server 8080 -d $DOCS_DIR"
