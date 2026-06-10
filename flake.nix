{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
     nixosConfigurations = {
	      solidus = nixpkgs.lib.nixosSystem {
	      system = "x86_64-linux"; 
	      modules = [
		      ./configuration.nix
	         ];
	      };
      };
   };
}
