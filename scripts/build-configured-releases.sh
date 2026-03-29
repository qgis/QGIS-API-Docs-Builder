#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# QGIS API Documentation Builder - Build Configured Releases with Theme
# ═══════════════════════════════════════════════════════════════════════════════
#
# Builds QGIS API documentation for all configured releases with custom theme.
# Supports both flake-based builds (modern releases) and legacy CMake/Doxygen
# builds (older releases without flake.nix).
#
# Made with 💗 by Kartoza | https://kartoza.com
#
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
THEME_DIR="$PROJECT_DIR/theme"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_DIR/docs-output}"
LOG_DIR="$PROJECT_DIR/build-logs"
SKIP_LEGACY="${SKIP_LEGACY:-false}"
ONLY_LEGACY="${ONLY_LEGACY:-false}"
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# Clear previous logs
rm -f "$LOG_DIR/successful.txt" "$LOG_DIR/failed.txt"

# Read releases dynamically from releases.nix (including useLegacyBuild flag)
echo "Reading releases from releases.nix..."
RELEASES_RAW=$(nix eval --raw "$PROJECT_DIR#lib.releases" --apply 'releases:
  builtins.concatStringsSep "\n" (
    builtins.map (name:
      let r = releases.${name};
      in "${r.branch}:${r.version}:${if r.useLegacyBuild or false then "legacy" else "flake"}"
    ) (builtins.attrNames releases)
  )
')

# Convert to array
mapfile -t RELEASES <<< "$RELEASES_RAW"
echo "Found ${#RELEASES[@]} releases to build"

apply_theme() {
  local docs_dir="$1"
  local html_dir="$docs_dir"

  if [[ ! -f "$html_dir/index.html" ]]; then
    echo "  Warning: Could not find index.html in $docs_dir"
    return 1
  fi

  # Copy theme files
  cp "$THEME_DIR/doxygen-awesome.css" "$html_dir/"
  cp "$THEME_DIR/doxygen-awesome-sidebar-only.css" "$html_dir/"
  cp "$THEME_DIR/doxygen-awesome-sidebar-only-darkmode-toggle.css" "$html_dir/"
  cp "$THEME_DIR/doxygen-awesome-darkmode-toggle.js" "$html_dir/"
  cp "$THEME_DIR/qgis-theme.css" "$html_dir/"

  # CSS injection string
  local CSS_INJECT='<link rel="stylesheet" href="doxygen-awesome.css"/><link rel="stylesheet" href="doxygen-awesome-sidebar-only.css"/><link rel="stylesheet" href="doxygen-awesome-sidebar-only-darkmode-toggle.css"/><link rel="stylesheet" href="qgis-theme.css"/><script src="doxygen-awesome-darkmode-toggle.js"></script>'

  # Inject CSS into all HTML files
  find "$html_dir" -name "*.html" -type f | while read -r html_file; do
    if ! grep -q "doxygen-awesome.css" "$html_file" 2>/dev/null; then
      sed -i "s|</head>|${CSS_INJECT}</head>|" "$html_file"
    fi
  done

  echo "  Theme applied"
}

# ─────────────────────────────────────────────────────────────────────────────
# Build using QGIS flake's docs package (for modern releases with flake.nix)
# ─────────────────────────────────────────────────────────────────────────────
build_flake_release() {
  local branch="$1"
  local version="$2"
  local log_file="$LOG_DIR/${version}.log"

  echo ""
  echo "[$(date '+%H:%M:%S')] ═══════════════════════════════════════════════"
  echo "[$(date '+%H:%M:%S')] Building $version ($branch) [flake]..."
  echo "[$(date '+%H:%M:%S')] ═══════════════════════════════════════════════"

  # Create temp flake
  local temp_dir
  temp_dir=$(mktemp -d)

  cat > "$temp_dir/flake.nix" << FLAKE
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    qgis.url = "github:qgis/QGIS/$branch";
  };
  outputs = { self, nixpkgs, flake-utils, qgis }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages.default = qgis.packages.\${system}.docs;
    });
}
FLAKE

  local out_path
  if out_path=$(nix build "$temp_dir#default" --no-link --print-out-paths 2>&1 | tee "$log_file" | tail -1) && [[ -d "$out_path" ]]; then
    echo "[$(date '+%H:%M:%S')] ✓ Built: $out_path"

    # Copy to output directory (makes it writable)
    # The QGIS docs are nested under a 'master' subdirectory - flatten this
    mkdir -p "$OUTPUT_DIR/$version"
    if [[ -d "$out_path/master" ]]; then
      rsync -a --copy-links "$out_path/master/" "$OUTPUT_DIR/$version/"
    else
      rsync -a --copy-links "$out_path/" "$OUTPUT_DIR/$version/"
    fi
    chmod -R u+w "$OUTPUT_DIR/$version"

    # Apply theme
    echo "[$(date '+%H:%M:%S')] Applying theme..."
    apply_theme "$OUTPUT_DIR/$version"

    echo "$version" >> "$LOG_DIR/successful.txt"
    echo "[$(date '+%H:%M:%S')] ✓ $version complete"
  else
    echo "[$(date '+%H:%M:%S')] ✗ $version FAILED (see $log_file)"
    echo "$version" >> "$LOG_DIR/failed.txt"
  fi

  rm -rf "$temp_dir"
}

# ─────────────────────────────────────────────────────────────────────────────
# Build using CMake/Doxygen (for older releases without flake.nix)
# ─────────────────────────────────────────────────────────────────────────────
build_legacy_release() {
  local branch="$1"
  local version="$2"
  local log_file="$LOG_DIR/${version}.log"

  echo ""
  echo "[$(date '+%H:%M:%S')] ═══════════════════════════════════════════════"
  echo "[$(date '+%H:%M:%S')] Building $version ($branch) [legacy/cmake]..."
  echo "[$(date '+%H:%M:%S')] ═══════════════════════════════════════════════"

  local work_dir
  work_dir=$(mktemp -d)

  # Use nix-shell to get build dependencies
  (
    cd "$work_dir"

    echo "[$(date '+%H:%M:%S')] Cloning QGIS $branch..."
    git clone --depth 1 --branch "$branch" https://github.com/qgis/QGIS.git qgis 2>&1 | tee -a "$log_file"
    cd qgis

    echo "[$(date '+%H:%M:%S')] Configuring CMake..."
    mkdir -p build && cd build

    # Run cmake with minimal options for doc generation only
    cmake .. \
      -DWITH_APIDOC=ON \
      -DWITH_GUI=OFF \
      -DWITH_DESKTOP=OFF \
      -DWITH_3D=OFF \
      -DWITH_PDAL=OFF \
      -DWITH_GRASS=OFF \
      -DWITH_SERVER=OFF \
      -DWITH_BINDINGS=OFF \
      -DWITH_QGIS_PROCESS=OFF \
      -DWITH_QUICK=OFF \
      2>&1 | tee -a "$log_file" || echo "CMake config had warnings (continuing)"

    echo "[$(date '+%H:%M:%S')] Building API documentation..."
    make apidoc 2>&1 | tee -a "$log_file"

    # Find and copy the generated docs
    mkdir -p "$OUTPUT_DIR/$version"
    if [[ -d "doc/api/html" ]]; then
      rsync -a doc/api/html/ "$OUTPUT_DIR/$version/"
    elif [[ -d "../doc/api/html" ]]; then
      rsync -a ../doc/api/html/ "$OUTPUT_DIR/$version/"
    else
      echo "[$(date '+%H:%M:%S')] Looking for generated docs..."
      find . -name "index.html" -path "*/api/*" 2>/dev/null || true
      echo "[$(date '+%H:%M:%S')] ✗ Could not find generated docs"
      echo "$version" >> "$LOG_DIR/failed.txt"
      return 1
    fi

    chmod -R u+w "$OUTPUT_DIR/$version"

    # Apply theme
    echo "[$(date '+%H:%M:%S')] Applying theme..."
    apply_theme "$OUTPUT_DIR/$version"

    echo "$version" >> "$LOG_DIR/successful.txt"
    echo "[$(date '+%H:%M:%S')] ✓ $version complete"

  ) || {
    echo "[$(date '+%H:%M:%S')] ✗ $version FAILED (see $log_file)"
    echo "$version" >> "$LOG_DIR/failed.txt"
  }

  rm -rf "$work_dir"
}

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║   Building QGIS API Documentation with doxygen-awesome theme     ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo "Theme directory: $THEME_DIR"
echo "Skip legacy builds: $SKIP_LEGACY"
echo "Only legacy builds: $ONLY_LEGACY"
echo ""

# Check theme files exist
if [[ ! -f "$THEME_DIR/doxygen-awesome.css" ]]; then
  echo "Error: Theme files not found in $THEME_DIR"
  echo "Run: cd theme && curl -sL https://raw.githubusercontent.com/jothepro/doxygen-awesome-css/main/doxygen-awesome.css -o doxygen-awesome.css"
  exit 1
fi

# Build index page first
echo "Building index page..."
INDEX_PATH=$(nix build "$PROJECT_DIR#index" --no-link --print-out-paths 2>/dev/null)
cp -r "$INDEX_PATH"/* "$OUTPUT_DIR/"
chmod -R u+w "$OUTPUT_DIR"
echo "✓ Index page ready"

# Build releases
for release in "${RELEASES[@]}"; do
  IFS=':' read -r branch version build_type <<< "$release"

  # Skip based on flags
  if [[ "$SKIP_LEGACY" == "true" && "$build_type" == "legacy" ]]; then
    echo "[$(date '+%H:%M:%S')] Skipping $version (legacy build disabled)"
    continue
  fi

  if [[ "$ONLY_LEGACY" == "true" && "$build_type" != "legacy" ]]; then
    echo "[$(date '+%H:%M:%S')] Skipping $version (only building legacy releases)"
    continue
  fi

  if [[ "$build_type" == "legacy" ]]; then
    build_legacy_release "$branch" "$version"
  else
    build_flake_release "$branch" "$version"
  fi
done

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                        BUILD COMPLETE                             ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Output directory: $OUTPUT_DIR"
if [[ -f "$LOG_DIR/successful.txt" ]]; then
  echo ""
  echo "Successful builds:"
  cat "$LOG_DIR/successful.txt" | sed 's/^/  ✓ /'
fi
if [[ -f "$LOG_DIR/failed.txt" ]]; then
  echo ""
  echo "Failed builds:"
  cat "$LOG_DIR/failed.txt" | sed 's/^/  ✗ /'
fi
echo ""
echo "To serve: python -m http.server 8080 -d $OUTPUT_DIR"
