{
  description = "A simple rust flake using rust-overlay and craneLib";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
  };

  outputs = {
    crane,
    flake-utils,
    nixpkgs,
    rust-overlay,
    advisory-db,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [rust-overlay.overlays.default];
        };
        inherit (pkgs) lib;

        stableToolchain = pkgs.rust-bin.stable.latest.default;
        stableToolchainWithLLvmTools = pkgs.rust-bin.stable.latest.default.override {
          extensions = ["rust-src" "llvm-tools"];
        };
        stableToolchainWithRustAnalyzer = pkgs.rust-bin.stable.latest.default.override {
          extensions = ["rust-src" "rust-analyzer"];
          # Extra targets if required
          # targets = [
          #   "x86_64-unknown-linux-gnu"
          #   "x86_64-unknown-linux-musl"
          #   "x86_64-apple-darwin"
          #   "aarch64-apple-darwin"
          # ];
        };
        craneLib = (crane.mkLib pkgs).overrideToolchain stableToolchain;
        craneLibLLvmTools = (crane.mkLib pkgs).overrideToolchain stableToolchainWithLLvmTools;
        sourceFilters = path: type: (craneLib.filterCargoSources path type) || (lib.hasSuffix ".h" path || lib.hasSuffix ".c" path);
        src = lib.cleanSourceWith {
          filter = sourceFilters;
          src = ./.;
        };
        commonArgs = {
          inherit src;
          buildInputs = with pkgs;
            []
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              libiconv
              # pkgs.darwin.apple_sdk.frameworks.Foundation
              # pkgs.darwin.apple_sdk.frameworks.CoreServices
            ]; # Inputs required for the TARGET system

          nativeBuildInputs = with pkgs; [
            # often required for c/c++ libs
            pkg-config
            rustPlatform.bindgenHook
          ]; # Intputs required for the HOST system
          # This is often requird for any ffi based packages that use bindgen
          # LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          # For using pkg-config that many libraries require
          # PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" (with pkgs;[ openssl.dev zlib.dev ]);
        };
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        hello = craneLib.buildPackage (commonArgs
          // {
            inherit cargoArtifacts;
          });
      in {
        checks =
          {
            hello-clippy = craneLib.cargoClippy (commonArgs
              // {
                inherit cargoArtifacts;
                cargoClippyExtraArgs = "--all-targets -- --deny warnings";
              });
            hello-docs = craneLib.cargoDoc (commonArgs // {inherit cargoArtifacts;});
            hello-fmt = craneLib.cargoFmt {inherit src;};
            hello-toml-fmt = craneLib.taploFmt {
              src = pkgs.lib.sources.sourceFilesBySuffices src [".toml"];
            };
            # Audit dependencies
            hello-audit = craneLib.cargoAudit {
              inherit src advisory-db;
            };

            # Audit licenses
            hello-deny = craneLib.cargoDeny {
              inherit src;
            };
            hello-nextest = craneLib.cargoNextest (commonArgs
              // {
                inherit cargoArtifacts;
                partitions = 1;
                partitionType = "count";
              });
          }
          // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
            hello-llvm-cov = craneLibLLvmTools.cargoLlvmCov (commonArgs // {inherit cargoArtifacts;});
          };

        packages.hello = hello;

        devShells.default = (craneLib.overrideToolchain stableToolchainWithRustAnalyzer).devShell (commonArgs
          // {
            packages = with pkgs; [
              cargo-nextest
              cargo-criterion
            ];
          });
      }
    );
}
