{
  description = "NixOS systems for the homelab";

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs.git?ref=nixos-26.05&rev=b3fe9581c9061c749abef42b6d4ee7b7c05c33fa&shallow=1";
    disko = {
      url = "git+https://github.com/nix-community/disko.git?ref=master&rev=ff8702b4de27f72b4c78573dfb89ec74e36abdf1&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixosAnywhereSrc = {
      url = "git+https://github.com/nix-community/nixos-anywhere.git?ref=1.13.0&rev=bad98b0685cf47eaeadcaf6787da8b51cf025693&shallow=1";
      flake = false;
    };
  };

  outputs = { nixpkgs, disko, nixosAnywhereSrc, ... }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    {
      packages = nixpkgs.lib.genAttrs supportedSystems (system: {
        nixos-anywhere = nixpkgs.legacyPackages.${system}.nixos-anywhere.overrideAttrs (_: {
          src = nixosAnywhereSrc;
        });
      });

      nixosConfigurations.shared = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./disk-config.nix
          ./shared.nix
        ];
      };
    };
}
