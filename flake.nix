{
  description = "fionns flakey goodness";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs, nixpkgs-unstable, ... }: 
  let
    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in
  {
    nixosConfigurations = {
      solidus = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
        ];
        specialArgs = {
          inherit pkgs-unstable;
        };
      };
    };
  };
}
