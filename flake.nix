{
  description = "Pants build system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        pants = pkgs.stdenv.mkDerivation rec {
          pname = "pants";
          version = "0.12.0";

          src = pkgs.fetchurl {
            url = "https://github.com/pantsbuild/scie-pants/releases/download/v${version}/scie-${pname}-${
              {
                "x86_64-linux" = "linux-x86_64";
                "aarch64-linux" = "linux-aarch64";
                "x86_64-darwin" = "macos-x86_64";
                "aarch64-darwin" = "macos-aarch64";
              }.${pkgs.stdenv.hostPlatform.system} or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}")
            }";
            hash = {
              x86_64-linux = "sha256-9PjgobndxVqDTYGtw1HESrtzwzH2qE9zFwR26xtwZrM=";
              aarch64-linux = "sha256-Hu1vKlT+7qFvNZztPNFtlWMrteJ4Uk3zcQNJVOD9pGE=";
              x86_64-darwin = "sha256-4sutOlvvX7WZzU1DaX2qwTr6LM5KRYJxAa4w2bijMAA=";
              aarch64-darwin = "sha256-1Ha8GAOl7mWVunGKf7INMjar+jnLXaDEPStqE+kK3D4=";
            }.${pkgs.stdenv.hostPlatform.system} or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
          };

          phases = [ "installPhase" "patchPhase" ];
          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/pants
            chmod +x $out/bin/pants
          '';

          meta = with pkgs.lib; {
            description = "Protects your Pants from the elements";
            homepage = "https://github.com/pantsbuild/scie-pants";
            license = licenses.asl20;
            maintainers = [ ];
            platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
            mainProgram = "pants";
          };
        };

        pantsWrapper = pkgs.writeShellScriptBin "pants" ''
          #!/usr/bin/env bash
          export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          exec ${pants}/bin/pants "$@"
        '';

      in
      {
        packages = rec {
          default = pantsWrapper;
          inherit pants pantsWrapper;
        };

        apps = {
          default = flake-utils.lib.mkApp { drv = pantsWrapper; };
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}