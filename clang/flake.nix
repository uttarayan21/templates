{
  description = "A very basic clang devshell flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [
        (final: prev: {
        })
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
    in {
      # packages = {
      # };
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [clang pkg-config];
        buildInputs = with pkgs; [libiconv];
        # PKG_CONFIG_PATH = pkgs.lib.makeSearchPath "lib/pkgconfig" (with pkgs; [ncnn]);
        packages = with pkgs; [];
      };
    });
}
