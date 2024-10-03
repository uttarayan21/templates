{
  description = "A very basic yarn devshell flake";

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
        nativeBuildInputs = with pkgs; [clang pkg-config yarn nodejs];
        buildInputs = with pkgs; [
          libiconv
          darwin.apple_sdk.frameworks.CoreFoundation
        ];
        # PKG_CONFIG_PATH = pkgs.lib.makeSearchPath "lib/pkgconfig" (with pkgs; [ncnn]);
        packages = with pkgs; [];
      };
    });
}
