{
  description = "Grafana module for Fudo systems.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    arion.url = "github:hercules-ci/arion";
    arion.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, arion, ... }: {
    nixosModules = rec {
      default = grafana;
      grafana = { ... }: {
        imports = [ arion.nixosModules.arion ./grafana.nix ];
      };
    };
  };
}
