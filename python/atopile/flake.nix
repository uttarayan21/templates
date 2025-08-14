{
  description = "Simple python flake";
  inputs.flake-utils.url = "github:numtide/flake-utils";

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
            packages = with pkgs; [
              (python312.withPackages (ps:
                with ps; [
                  # matplotlib
                  # numpy
                  atopile
                  just
                ]))
            ];
          };
        };
      }
    );
}
