{
  description = "QGIS API Documentation Builder - Multi-release documentation with web server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Import the QGIS flake for master branch
    qgis = {
      url = "github:qgis/QGIS";
      flake = true;
    };
  };

  # Note: After setting up Cachix, add this nixConfig:
  # nixConfig = {
  #   extra-substituters = [ "https://YOUR-CACHE.cachix.org" ];
  #   extra-trusted-public-keys = [ "YOUR-CACHE.cachix.org-1:YOUR_PUBLIC_KEY" ];
  # };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      qgis,
    }:
    let
      # Load release definitions
      releases = import ./releases.nix;

      # Sort releases by order field (master first, then newest to oldest)
      sortedReleases = builtins.sort (a: b: a.order < b.order) (builtins.attrValues releases);

      # Helper to generate release card HTML
      mkReleaseCard = release: ''
        <a href="./${release.version}/" class="release-card">
          <div class="release-header">
            <span class="release-version">${release.version}</span>
            <div class="release-badges">
              ${if release.isLTS then ''<span class="badge badge-lts">LTS</span>'' else ""}
              ${if release.isLatest then ''<span class="badge badge-latest">Latest</span>'' else ""}
              ${if release.isMaster then ''<span class="badge badge-dev">Dev</span>'' else ""}
            </div>
          </div>
          <p class="release-description">
            ${if release.isMaster then "Development version - updated nightly with latest features and changes."
              else if release.isLTS then "Long Term Support release - recommended for stable plugin development."
              else "Regular release - includes new features and improvements."}
          </p>
          <span class="release-link">
            Browse API Documentation
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
          </span>
        </a>
      '';

      # System-specific outputs
      systemOutputs = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                libspatialindex = prev.libspatialindex.overrideAttrs (old: rec {
                  version = "2.0.0";
                  src = final.fetchFromGitHub {
                    owner = "libspatialindex";
                    repo = "libspatialindex";
                    rev = "refs/tags/${version}";
                    hash = "sha256-hZyAXz1ddRStjZeqDf4lYkV/g0JLqLy7+GrSUh75k20=";
                  };
                });
              })
            ];
          };

          # Get the QGIS docs package from the QGIS flake (master)
          qgisDocsRaw = qgis.packages.${system}.docs;

          # ─────────────────────────────────────────────────────────────────────
          # Theme files package
          # ─────────────────────────────────────────────────────────────────────
          themeFiles = pkgs.runCommand "qgis-docs-theme" {} ''
            mkdir -p $out
            cp ${./theme/doxygen-awesome.css} $out/doxygen-awesome.css
            cp ${./theme/doxygen-awesome-sidebar-only.css} $out/doxygen-awesome-sidebar-only.css
            cp ${./theme/doxygen-awesome-sidebar-only-darkmode-toggle.css} $out/doxygen-awesome-sidebar-only-darkmode-toggle.css
            cp ${./theme/doxygen-awesome-darkmode-toggle.js} $out/doxygen-awesome-darkmode-toggle.js
            cp ${./theme/qgis-theme.css} $out/qgis-theme.css
          '';

          # ─────────────────────────────────────────────────────────────────────
          # Apply theme to docs (creates new derivation, doesn't modify store)
          # ─────────────────────────────────────────────────────────────────────
          applyTheme = rawDocs: pkgs.runCommand "qgis-docs-themed" {
            buildInputs = [ pkgs.gnused pkgs.findutils ];
          } ''
            # Copy docs to output (makes them writable)
            cp -r ${rawDocs} $out
            chmod -R u+w $out

            # Find the actual docs directory
            DOCS_DIR=$(find $out -name "index.html" -type f -exec dirname {} \; | head -1)

            if [[ -z "$DOCS_DIR" ]]; then
              echo "Error: Could not find docs directory"
              exit 1
            fi

            # Copy theme files
            cp ${themeFiles}/* "$DOCS_DIR/"

            # CSS injection string
            CSS_INJECT='<link rel="stylesheet" href="doxygen-awesome.css"/><link rel="stylesheet" href="doxygen-awesome-sidebar-only.css"/><link rel="stylesheet" href="doxygen-awesome-sidebar-only-darkmode-toggle.css"/><link rel="stylesheet" href="qgis-theme.css"/><script src="doxygen-awesome-darkmode-toggle.js"></script>'

            # Inject CSS into all HTML files
            find "$DOCS_DIR" -name "*.html" -type f | while read -r html_file; do
              if ! grep -q "doxygen-awesome.css" "$html_file" 2>/dev/null; then
                sed -i "s|</head>|$CSS_INJECT</head>|" "$html_file"
              fi
            done

            echo "Theme applied to docs"
          '';

          # ─────────────────────────────────────────────────────────────────────
          # Legacy build for releases without flake.nix
          # Uses traditional cmake/doxygen approach
          # ─────────────────────────────────────────────────────────────────────
          buildLegacyDocs = { branch, version }: pkgs.stdenv.mkDerivation {
            pname = "qgis-api-documentation-legacy";
            inherit version;

            src = pkgs.fetchFromGitHub {
              owner = "qgis";
              repo = "QGIS";
              rev = branch;
              hash = ""; # Will need to be filled per-branch or use fetchGit
            };

            nativeBuildInputs = with pkgs; [
              cmake
              doxygen
              graphviz
              python3
              flex
              bison
            ];

            buildInputs = with pkgs; [
              qt5.qtbase
              qt5.qttools
              qt5.qtsvg
              qt5.qtwebkit
            ];

            dontConfigure = false;
            dontBuild = false;

            configurePhase = ''
              runHook preConfigure
              mkdir -p build && cd build
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
                -DWITH_QUICK=OFF
              runHook postConfigure
            '';

            buildPhase = ''
              runHook preBuild
              make apidoc
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out
              cp -r doc/api/html/* $out/ || cp -r ../doc/api/html/* $out/ || true
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "QGIS API Documentation (legacy build)";
              homepage = "https://qgis.org";
              license = licenses.gpl2Plus;
            };
          };

          # ─────────────────────────────────────────────────────────────────────
          # Script to build legacy docs for a branch
          # ─────────────────────────────────────────────────────────────────────
          buildLegacyScript = pkgs.writeShellApplication {
            name = "build-legacy-docs";
            runtimeInputs = with pkgs; [
              git
              cmake
              doxygen
              graphviz
              python3
              gnused
              findutils
              rsync
              qt5.qtbase
              qt5.qttools
            ];
            text = ''
              set -euo pipefail

              BRANCH="''${1:-}"
              VERSION="''${2:-}"
              OUTPUT_DIR="''${OUTPUT_DIR:-./docs-output}"
              THEME_DIR="''${THEME_DIR:-${./theme}}"

              if [[ -z "$BRANCH" ]]; then
                echo "Usage: build-legacy-docs <branch> [version]"
                echo "Example: build-legacy-docs release-3_34 3.34"
                exit 1
              fi

              # Extract version from branch if not provided
              if [[ -z "$VERSION" ]]; then
                VERSION=$(echo "$BRANCH" | sed 's/release-//' | tr '_' '.')
              fi

              echo ""
              echo "╔═══════════════════════════════════════════════════════════════════╗"
              echo "║   Building QGIS API Docs (Legacy) - $VERSION                      ║"
              echo "╚═══════════════════════════════════════════════════════════════════╝"
              echo ""

              WORK_DIR=$(mktemp -d)
              cleanup() { rm -rf "$WORK_DIR"; }
              trap cleanup EXIT

              echo "Cloning QGIS $BRANCH..."
              git clone --depth 1 --branch "$BRANCH" https://github.com/qgis/QGIS.git "$WORK_DIR/qgis"
              cd "$WORK_DIR/qgis"

              echo "Configuring CMake..."
              mkdir -p build && cd build
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
                2>/dev/null || echo "CMake warnings ignored"

              echo "Building API documentation..."
              make apidoc

              echo "Copying to output..."
              mkdir -p "$OUTPUT_DIR/$VERSION"

              # Find and copy the generated docs
              if [[ -d "doc/api/html" ]]; then
                rsync -a doc/api/html/ "$OUTPUT_DIR/$VERSION/"
              elif [[ -d "../doc/api/html" ]]; then
                rsync -a ../doc/api/html/ "$OUTPUT_DIR/$VERSION/"
              else
                echo "Error: Could not find generated docs"
                find . -name "index.html" -path "*/api/*" 2>/dev/null || true
                exit 1
              fi

              # Apply theme
              echo "Applying theme..."
              cp "$THEME_DIR/doxygen-awesome.css" "$OUTPUT_DIR/$VERSION/"
              cp "$THEME_DIR/doxygen-awesome-sidebar-only.css" "$OUTPUT_DIR/$VERSION/"
              cp "$THEME_DIR/doxygen-awesome-sidebar-only-darkmode-toggle.css" "$OUTPUT_DIR/$VERSION/"
              cp "$THEME_DIR/doxygen-awesome-darkmode-toggle.js" "$OUTPUT_DIR/$VERSION/"
              cp "$THEME_DIR/qgis-theme.css" "$OUTPUT_DIR/$VERSION/"

              CSS_INJECT='<link rel="stylesheet" href="doxygen-awesome.css"/><link rel="stylesheet" href="doxygen-awesome-sidebar-only.css"/><link rel="stylesheet" href="doxygen-awesome-sidebar-only-darkmode-toggle.css"/><link rel="stylesheet" href="qgis-theme.css"/><script src="doxygen-awesome-darkmode-toggle.js"></script>'

              find "$OUTPUT_DIR/$VERSION" -name "*.html" -type f | while read -r html_file; do
                if ! grep -q "doxygen-awesome.css" "$html_file" 2>/dev/null; then
                  sed -i "s|</head>|$CSS_INJECT</head>|" "$html_file"
                fi
              done

              echo ""
              echo "✓ $VERSION complete at $OUTPUT_DIR/$VERSION"
            '';
          };

          # Themed docs for master
          qgisDocs = applyTheme qgisDocsRaw;

          # ─────────────────────────────────────────────────────────────────────
          # Generate release cards HTML file (sorted: master first, newest to oldest)
          # ─────────────────────────────────────────────────────────────────────
          releaseCardsHtml = pkgs.writeText "release-cards.html"
            (builtins.concatStringsSep "\n" (builtins.map mkReleaseCard sortedReleases));

          # ─────────────────────────────────────────────────────────────────────
          # Generate index page
          # ─────────────────────────────────────────────────────────────────────
          indexPage = pkgs.runCommand "qgis-api-docs-index" {
            buildInputs = [ pkgs.gnused ];
          } ''
            mkdir -p $out

            # Read template and cards
            TEMPLATE=$(cat ${./templates/index.html})
            CARDS=$(cat ${releaseCardsHtml})
            BUILD_DATE=$(date -u '+%Y-%m-%d %H:%M UTC')

            # Use awk for safer substitution
            echo "$TEMPLATE" | awk -v cards="$CARDS" '{gsub(/<!-- RELEASES_PLACEHOLDER -->/, cards); print}' | \
              awk -v date="$BUILD_DATE" '{gsub(/<!-- BUILD_DATE_PLACEHOLDER -->/, date); print}' > $out/index.html
          '';

          # ─────────────────────────────────────────────────────────────────────
          # Build script for a single release
          # ─────────────────────────────────────────────────────────────────────
          buildReleaseScript = pkgs.writeShellApplication {
            name = "build-release";
            runtimeInputs = with pkgs; [ git coreutils nix cachix gnused ];
            text = builtins.readFile ./scripts/build-release.sh;
          };

          # ─────────────────────────────────────────────────────────────────────
          # Build all releases script
          # ─────────────────────────────────────────────────────────────────────
          buildAllReleasesScript = pkgs.writeShellApplication {
            name = "build-all-releases";
            runtimeInputs = with pkgs; [
              git coreutils gnused gnugrep gawk cachix nix
            ];
            text = builtins.readFile ./scripts/build-all-releases.sh;
          };

          # ─────────────────────────────────────────────────────────────────────
          # Clean Script
          # ─────────────────────────────────────────────────────────────────────
          cleanScript = pkgs.writeShellApplication {
            name = "clean-build";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              BUILD_DIR="''${BUILD_DIR:-./build}"
              OUTPUT_DIR="''${OUTPUT_DIR:-./output}"
              echo "Cleaning build artifacts..."
              if [[ -d "$BUILD_DIR" ]]; then
                rm -rf "$BUILD_DIR"
                echo "  Removed: $BUILD_DIR"
              fi
              if [[ -d "$OUTPUT_DIR" ]]; then
                rm -rf "$OUTPUT_DIR"
                echo "  Removed: $OUTPUT_DIR"
              fi
              echo "Clean complete."
            '';
          };

          # ─────────────────────────────────────────────────────────────────────
          # Serve Script
          # ─────────────────────────────────────────────────────────────────────
          serveDocsScript = pkgs.writeShellApplication {
            name = "serve-docs";
            runtimeInputs = [ pkgs.python3 ];
            text = ''
              PORT="''${PORT:-8080}"
              DOCS_PATH="''${1:-${qgisDocs}}"

              echo ""
              echo "╔═══════════════════════════════════════════════════════════════════╗"
              echo "║           QGIS API Documentation Server                           ║"
              echo "║                                                                   ║"
              echo "║   Made with 💗 by Kartoza | https://kartoza.com                   ║"
              echo "╚═══════════════════════════════════════════════════════════════════╝"
              echo ""
              echo "Serving QGIS API docs at http://localhost:$PORT"
              echo "Press Ctrl+C to stop"
              echo ""
              exec python -m http.server "$PORT" -d "$DOCS_PATH"
            '';
          };

          # ─────────────────────────────────────────────────────────────────────
          # Local test server - serves the index page with mock version dirs
          # ─────────────────────────────────────────────────────────────────────
          localTestScript = pkgs.writeShellApplication {
            name = "local-test";
            runtimeInputs = with pkgs; [ python3 coreutils ];
            text = ''
              PORT="''${PORT:-8080}"
              TEMP_DIR=$(mktemp -d)
              cleanup() { rm -rf "$TEMP_DIR"; }
              trap cleanup EXIT

              echo ""
              echo "╔═══════════════════════════════════════════════════════════════════╗"
              echo "║           QGIS API Documentation - Local Test Server              ║"
              echo "╚═══════════════════════════════════════════════════════════════════╝"
              echo ""

              # Copy index page
              cp -r ${indexPage}/* "$TEMP_DIR/"

              # Create placeholder directories for each version
              ${builtins.concatStringsSep "\n" (builtins.map (name: ''
                mkdir -p "$TEMP_DIR/${releases.${name}.version}"
                cat > "$TEMP_DIR/${releases.${name}.version}/index.html" << 'PLACEHOLDER'
              <!DOCTYPE html>
              <html>
              <head>
                <title>QGIS ${releases.${name}.version} API Documentation</title>
                <style>
                  body { font-family: system-ui; max-width: 800px; margin: 50px auto; padding: 20px; }
                  h1 { color: #589632; }
                  .back { margin-top: 20px; }
                  a { color: #589632; }
                </style>
              </head>
              <body>
                <h1>QGIS ${releases.${name}.version} API Documentation</h1>
                <p>This is a placeholder page for local testing.</p>
                <p>In production, this would contain the full Doxygen-generated API documentation for QGIS ${releases.${name}.version}.</p>
                <p class="back"><a href="/">← Back to version index</a></p>
                <hr>
                <p><small>Made with 💗 by <a href="https://kartoza.com">Kartoza</a></small></p>
              </body>
              </html>
              PLACEHOLDER
              '') (builtins.attrNames releases))}

              echo "Serving at: http://localhost:$PORT"
              echo "Press Ctrl+C to stop"
              echo ""
              exec python -m http.server "$PORT" -d "$TEMP_DIR"
            '';
          };

          # ─────────────────────────────────────────────────────────────────────
          # Full local test - assembles real docs and serves them
          # ─────────────────────────────────────────────────────────────────────
          fullLocalTestScript = pkgs.writeShellApplication {
            name = "full-local-test";
            runtimeInputs = with pkgs; [ python3 coreutils nix ];
            text = ''
              PORT="''${PORT:-8080}"
              DOCS_DIR="''${DOCS_DIR:-./qgis-api-docs-local-test}"

              echo ""
              echo "╔═══════════════════════════════════════════════════════════════════╗"
              echo "║           QGIS API Documentation - Full Local Test                ║"
              echo "╚═══════════════════════════════════════════════════════════════════╝"
              echo ""

              # Check if docs are already assembled
              if [[ ! -f "$DOCS_DIR/index.html" ]]; then
                echo "Assembling documentation (this may take a while on first run)..."
                echo "Docs will be cached in: $DOCS_DIR"
                echo ""
                ${assembleDocsScript}/bin/assemble-docs "$DOCS_DIR"
              else
                echo "Using existing docs in: $DOCS_DIR"
                echo "Delete this directory to force reassembly."
              fi

              echo ""
              echo "Serving at: http://localhost:$PORT"
              echo "Press Ctrl+C to stop"
              echo ""
              exec python -m http.server "$PORT" -d "$DOCS_DIR"
            '';
          };

          # ─────────────────────────────────────────────────────────────────────
          # Assemble docs script - combines all release docs into one directory
          # ─────────────────────────────────────────────────────────────────────
          assembleDocsScript = pkgs.writeShellApplication {
            name = "assemble-docs";
            runtimeInputs = with pkgs; [ coreutils nix jq ];
            text = ''
              OUTPUT_DIR="''${1:-./qgis-api-docs-site}"
              CACHIX_CACHE="''${CACHIX_CACHE:-qgis-api-docs}"

              echo ""
              echo "╔═══════════════════════════════════════════════════════════════════╗"
              echo "║           QGIS API Documentation - Site Assembler                 ║"
              echo "╚═══════════════════════════════════════════════════════════════════╝"
              echo ""

              # Create output directory
              mkdir -p "$OUTPUT_DIR"

              # Copy index page
              echo "Copying index page..."
              cp -r ${indexPage}/* "$OUTPUT_DIR/"

              # Define releases to assemble
              declare -A RELEASES=(
                ${builtins.concatStringsSep "\n" (
                  builtins.map (name: ''["${releases.${name}.version}"]="${releases.${name}.branch}"'')
                    (builtins.attrNames releases)
                )}
              )

              echo "Assembling documentation for ''${#RELEASES[@]} releases..."

              for VERSION in "''${!RELEASES[@]}"; do
                BRANCH="''${RELEASES[$VERSION]}"
                echo ""
                echo "Processing $VERSION ($BRANCH)..."

                # Create version directory
                mkdir -p "$OUTPUT_DIR/$VERSION"

                # Try to build/fetch the docs for this release
                TEMP_DIR=$(mktemp -d)
                cleanup() { rm -rf "$TEMP_DIR"; }
                trap cleanup EXIT

                cat > "$TEMP_DIR/flake.nix" << EOF
              {
                description = "QGIS API Documentation for $BRANCH";
                inputs = {
                  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
                  flake-utils.url = "github:numtide/flake-utils";
                  qgis = {
                    url = "github:qgis/QGIS/$BRANCH";
                    flake = true;
                  };
                };
                outputs = { self, nixpkgs, flake-utils, qgis }:
                  flake-utils.lib.eachDefaultSystem (system:
                    let
                      qgisDocs = qgis.packages.\''${system}.docs or null;
                    in {
                      packages = {
                        docs = if qgisDocs != null
                          then qgisDocs
                          else throw "Documentation not available for $BRANCH";
                        default = self.packages.\''${system}.docs;
                      };
                    }
                  );
              }
              EOF

                if OUT_PATH=$(nix build "$TEMP_DIR#docs" --no-link --print-out-paths 2>/dev/null); then
                  echo "  Copying docs from $OUT_PATH"
                  cp -rL "$OUT_PATH"/* "$OUTPUT_DIR/$VERSION/" 2>/dev/null || \
                    cp -r "$OUT_PATH"/* "$OUTPUT_DIR/$VERSION/"
                  echo "  Done: $VERSION"
                else
                  echo "  Warning: Could not build docs for $VERSION"
                  echo "<html><body><h1>Documentation unavailable</h1><p>Docs for $VERSION could not be built.</p></body></html>" > "$OUTPUT_DIR/$VERSION/index.html"
                fi
              done

              echo ""
              echo "Site assembled at: $OUTPUT_DIR"
              echo ""
              echo "To serve locally:"
              echo "  python -m http.server 8080 -d $OUTPUT_DIR"
            '';
          };

        in
        {
          # ═════════════════════════════════════════════════════════════════════
          # Development Shell
          # ═════════════════════════════════════════════════════════════════════
          devShells.default = pkgs.mkShell {
            name = "qgis-apidoc-builder";

            buildInputs = with pkgs; [
              doxygen
              graphviz
              python3
              git
              cachix
              jq
              qt6Packages.qttools
              (texlive.combine {
                inherit (texlive)
                  scheme-medium latex-bin latexmk collection-latexextra
                  collection-fontsrecommended collection-fontsextra
                  epstopdf adjustbox collectbox ucs wasysym wasy
                  sectsty tocloft newunicodechar etoc;
              })
            ];

            shellHook = ''
              echo ""
              echo "╔═══════════════════════════════════════════════════════════════════╗"
              echo "║           QGIS API Documentation Builder                          ║"
              echo "╚═══════════════════════════════════════════════════════════════════╝"
              echo ""
              echo "Single Release Commands:"
              echo "  nix build .#docs             - Build master docs"
              echo "  nix run .#serve              - Serve master docs locally"
              echo "  nix run .#build-release -- <branch>  - Build specific release"
              echo ""
              echo "Multi-Release Commands:"
              echo "  nix run .#build-all-releases - Build all configured releases"
              echo "  nix run .#assemble-docs      - Assemble complete documentation site"
              echo ""
              echo "Local Testing:"
              echo "  nix run .#local-test         - Serve index with placeholder docs"
              echo "  nix run .#full-local-test    - Assemble and serve full docs"
              echo ""
              echo "Deployment:"
              echo "  See nixosModules.qgis-api-docs for nginx + certbot deployment"
              echo ""
              echo "Made with 💗 by Kartoza | https://kartoza.com"
              echo ""
            '';
          };

          # ═════════════════════════════════════════════════════════════════════
          # Apps
          # ═════════════════════════════════════════════════════════════════════
          apps = {
            serve = {
              type = "app";
              program = "${serveDocsScript}/bin/serve-docs";
            };
            docs = {
              type = "app";
              program = "${serveDocsScript}/bin/serve-docs";
            };
            clean = {
              type = "app";
              program = "${cleanScript}/bin/clean-build";
            };
            build-release = {
              type = "app";
              program = "${buildReleaseScript}/bin/build-release";
            };
            build-all-releases = {
              type = "app";
              program = "${buildAllReleasesScript}/bin/build-all-releases";
            };
            build-legacy-docs = {
              type = "app";
              program = "${buildLegacyScript}/bin/build-legacy-docs";
            };
            assemble-docs = {
              type = "app";
              program = "${assembleDocsScript}/bin/assemble-docs";
            };
            # Local testing
            local-test = {
              type = "app";
              program = "${localTestScript}/bin/local-test";
            };
            full-local-test = {
              type = "app";
              program = "${fullLocalTestScript}/bin/full-local-test";
            };
            default = {
              type = "app";
              program = "${serveDocsScript}/bin/serve-docs";
            };
          };

          # ═════════════════════════════════════════════════════════════════════
          # Packages
          # ═════════════════════════════════════════════════════════════════════
          packages = {
            # Master branch docs (default)
            docs = qgisDocs;
            default = qgisDocs;

            # Index page
            index = indexPage;

            # Scripts
            serve-script = serveDocsScript;
            clean-script = cleanScript;
            build-release-script = buildReleaseScript;
            build-all-releases-script = buildAllReleasesScript;
            assemble-docs-script = assembleDocsScript;
            local-test-script = localTestScript;
            full-local-test-script = fullLocalTestScript;
          };
        }
      );

    in
    # Merge system-specific outputs with system-independent outputs
    systemOutputs // {
      # ═════════════════════════════════════════════════════════════════════
      # NixOS Module for deployment
      # ═════════════════════════════════════════════════════════════════════
      nixosModules.qgis-api-docs = { config, lib, pkgs, ... }:
        let
          cfg = config.services.qgis-api-docs;
        in
        {
          options.services.qgis-api-docs = {
            enable = lib.mkEnableOption "QGIS API Documentation web server";

            domain = lib.mkOption {
              type = lib.types.str;
              description = "Domain name for the documentation site";
              default = "api.qgis.org";
              example = "api.qgis.org";
            };

            docsPath = lib.mkOption {
              type = lib.types.path;
              description = "Path to the assembled documentation";
              example = "/var/www/qgis-api-docs";
            };

            enableACME = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable Let's Encrypt SSL certificate";
            };

            acmeEmail = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Email for Let's Encrypt notifications";
              example = "admin@example.com";
            };

            openFirewall = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Open firewall ports for HTTP and HTTPS";
            };

            extraNginxConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Extra nginx configuration for the virtual host";
            };
          };

          config = lib.mkIf cfg.enable {
            # Firewall
            networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 80 443 ];

            # ACME (Let's Encrypt)
            security.acme = lib.mkIf cfg.enableACME {
              acceptTerms = true;
              defaults.email = cfg.acmeEmail;
            };

            # Nginx
            services.nginx = {
              enable = true;
              recommendedGzipSettings = true;
              recommendedOptimisation = true;
              recommendedProxySettings = true;
              recommendedTlsSettings = true;

              virtualHosts.${cfg.domain} = {
                forceSSL = cfg.enableACME;
                enableACME = cfg.enableACME;

                root = cfg.docsPath;

                locations = {
                  "/" = {
                    index = "index.html";
                    tryFiles = "$uri $uri/ =404";
                  };

                  # Cache static assets
                  "~* \\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$" = {
                    extraConfig = ''
                      expires 30d;
                      add_header Cache-Control "public, immutable";
                    '';
                  };

                  # Doxygen search
                  "/search/" = {
                    extraConfig = ''
                      add_header Content-Type application/javascript;
                    '';
                  };
                };

                extraConfig = ''
                  # Security headers
                  add_header X-Frame-Options "SAMEORIGIN" always;
                  add_header X-Content-Type-Options "nosniff" always;
                  add_header X-XSS-Protection "1; mode=block" always;
                  add_header Referrer-Policy "strict-origin-when-cross-origin" always;

                  # Gzip for doxygen files
                  gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

                  ${cfg.extraNginxConfig}
                '';
              };
            };
          };
        };

      # ═════════════════════════════════════════════════════════════════════
      # Flake templates
      # ═════════════════════════════════════════════════════════════════════
      templates.deployment = {
        path = ./templates/deployment;
        description = "NixOS deployment configuration for QGIS API docs";
      };

      # Export releases for external use
      lib.releases = releases;
    };
}
