{
  description = "Grafana module for Fudo systems.";

  inputs = { nixpkgs.url = "nixpkgs/nixos-23.05"; };

  outputs = { self, nixpkgs, arion, ... }: {
    nixosModules = rec {
      default = grafana;
      grafana = { ... }: {
        imports = [ arion.nixosModules.arion ./grafana.nix ];
      };
    };
  };
}
