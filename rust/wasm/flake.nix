{
  description = "A simple rust flake using rust-overlay and craneLib";

  inputs = {
    main.url = "github:uttarayan21/templates";
    nixpkgs.follows = "main/nixpkgs";
    flake-utils.follows = "main/flake-utils";
    crane.follows = "main/crane";
    nix-github-actions.follows = "main/nix-github-actions";
    rust-overlay.follows = "main/rust-overlay";
    advisory-db.follows = "main/advisory-db";
  };

  outputs = {
    self,
    crane,
    flake-utils,
    nixpkgs,
    rust-overlay,
    advisory-db,
    nix-github-actions,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            rust-overlay.overlays.default
          ];
        };
        inherit (pkgs) lib;
        cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
        name = cargoToml.package.name;

        stableToolchain = pkgs.rust-bin.stable.latest.default;
        stableToolchainWithLLvmTools = stableToolchain.override {
          extensions = ["rust-src" "llvm-tools"];
        };
        stableToolchainWithRustAnalyzer = stableToolchain.override {
          extensions = ["rust-src" "rust-analyzer"];
        };
        craneLib = (crane.mkLib pkgs).overrideToolchain stableToolchain;
        craneLibLLvmTools = (crane.mkLib pkgs).overrideToolchain stableToolchainWithLLvmTools;

        src = let
          filterBySuffix = path: exts: lib.any (ext: lib.hasSuffix ext path) exts;
          sourceFilters = path: type: (craneLib.filterCargoSources path type) || filterBySuffix path [".c" ".h" ".hpp" ".cpp" ".cc"];
        in
          lib.cleanSourceWith {
            filter = sourceFilters;
            src = ./.;
          };
        commonArgs =
          {
            inherit src;
            pname = name;
            stdenv = p: p.clangStdenv;
            doCheck = false;
            # LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
            # nativeBuildInputs = with pkgs; [
            #   cmake
            #   llvmPackages.libclang.lib
            # ];
            buildInputs = with pkgs;
              []
              ++ (lib.optionals pkgs.stdenv.isDarwin [
                libiconv
                apple-sdk_26
              ]);
          }
          // (lib.optionalAttrs pkgs.stdenv.isLinux {
            # BINDGEN_EXTRA_CLANG_ARGS = "-I${pkgs.llvmPackages.libclang.lib}/lib/clang/18/include";
          });
        cargoArtifacts = craneLib.buildPackage commonArgs;
      in {
        checks =
          {
            "${name}-clippy" = craneLib.cargoClippy (commonArgs
              // {
                inherit cargoArtifacts;
                cargoClippyExtraArgs = "--all-targets -- --deny warnings";
              });
            "${name}-docs" = craneLib.cargoDoc (commonArgs // {inherit cargoArtifacts;});
            "${name}-fmt" = craneLib.cargoFmt {inherit src;};
            "${name}-toml-fmt" = craneLib.taploFmt {
              src = pkgs.lib.sources.sourceFilesBySuffices src [".toml"];
            };
            # Audit dependencies
            "${name}-audit" = craneLib.cargoAudit {
              inherit src advisory-db;
            };

            # Audit licenses
            "${name}-deny" = craneLib.cargoDeny {
              inherit src;
            };
            "${name}-nextest" = craneLib.cargoNextest (commonArgs
              // {
                inherit cargoArtifacts;
                partitions = 1;
                partitionType = "count";
              });
          }
          // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
            "${name}-llvm-cov" = craneLibLLvmTools.cargoLlvmCov (commonArgs // {inherit cargoArtifacts;});
          };

        packages = {
          "${name}" = craneLib.buildPackage (commonArgs // {inherit cargoArtifacts;});
        };

        devShells = {
          default = pkgs.mkShell.override {stdenv = pkgs.clangStdenv;} (commonArgs
            // {
              packages = with pkgs;
                [
                  stableToolchainWithRustAnalyzer
                  cargo-nextest
                  cargo-deny
                ]
                ++ (lib.optionals pkgs.stdenv.isDarwin [
                  apple-sdk_26
                ]);
            });
        };
      }
    )
    // {
      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks = nixpkgs.lib.getAttrs ["x86_64-linux"] self.checks;
      };
    };
}
