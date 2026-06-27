{
  description = "Simple python flake";
  inputs = {
    main.url = "github:uttarayan21/templates";
    nixpkgs.follows = "main/nixpkgs";
    flake-utils.follows = "main/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [(python3.withPackages (ps: with ps; [matplotlib numpy]))];
          };
        };
      }
    );
}
