{
  description = "NixOS configuration for Lenovo Legion 16ACH6H";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs: {
    nixosConfigurations = {
      legion = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Hardware support for Legion laptops
          nixos-hardware.nixosModules.lenovo-legion-16ach6h

          # Host-specific configuration
          ./hosts/legion/default.nix

          # Shared modules
          ./modules/nvidia.nix
          ./modules/desktop.nix

          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.therder = import ./home/default.nix;
          }
        ];
      };
    };
  };
}
