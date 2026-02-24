{
  description = "Cyberdan platform development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Infrastructure
            opentofu

            # Kubernetes
            kubectl
            kubernetes-helm
            kustomize
            argocd

            # Secrets
            sops
            age

            # Utilities
            jq
            yq-go
          ];
        };
      }
    );
}
