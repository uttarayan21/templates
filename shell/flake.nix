{
  description = "A very basic shell devshell flake";

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
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ] (system: let
      overlays = [
        (final: prev: {
        })
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
    in {
      devShells.default = pkgs.mkShell {
        # nativeBuildInputs = with pkgs; [];
        # buildInputs = with pkgs; [];
        packages = with pkgs; [];
      };
    });
}
