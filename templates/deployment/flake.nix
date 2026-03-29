{
  description = "QGIS API Documentation Server Deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    qgis-api-docs.url = "github:qgis/qgis-api-docs-builder";
  };

  outputs = { self, nixpkgs, qgis-api-docs }: {
    nixosConfigurations.qgis-api-docs-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Import the QGIS API docs module
        qgis-api-docs.nixosModules.qgis-api-docs

        # Server configuration
        ({ config, pkgs, ... }: {
          # Basic system config
          system.stateVersion = "24.05";

          networking.hostName = "qgis-api-docs";

          # Enable the QGIS API documentation service
          services.qgis-api-docs = {
            enable = true;
            domain = "api.qgis.org";
            docsPath = "/var/www/qgis-api-docs";
            enableACME = true;
            acmeEmail = "info@qgis.org";
            openFirewall = true;
          };

          # Systemd service to update docs periodically
          systemd.services.qgis-api-docs-update = {
            description = "Update QGIS API Documentation";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.writeShellScript "update-docs" ''
                #!/usr/bin/env bash
                set -euo pipefail

                DOCS_PATH="/var/www/qgis-api-docs"

                # Run the assemble-docs script
                ${qgis-api-docs.packages.x86_64-linux.assemble-docs-script}/bin/assemble-docs "$DOCS_PATH"

                # Set correct permissions
                chown -R nginx:nginx "$DOCS_PATH"
              ''}";
            };
          };

          # Timer to update docs nightly
          systemd.timers.qgis-api-docs-update = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "daily";
              Persistent = true;
              RandomizedDelaySec = "1h";
            };
          };

          # Ensure the docs directory exists
          systemd.tmpfiles.rules = [
            "d /var/www/qgis-api-docs 0755 nginx nginx -"
          ];
        })
      ];
    };
  };
}
