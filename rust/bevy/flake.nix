{
  description = "A Bevy engine flake for building and testing Rust projects with Bevy on Linux and MacOS.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crates-nix.url = "github:uttarayan21/crates.nix";
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
    self,
    crane,
    flake-utils,
    nixpkgs,
    rust-overlay,
    advisory-db,
    nix-github-actions,
    crates-nix,
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

        toolchain = pkgs.rust-bin.nightly.latest.default;
        toolchainWithLLvmTools = toolchain.override {
          extensions = ["rust-src" "llvm-tools"];
        };
        toolchainWithRustAnalyzer = toolchain.override {
          extensions = ["rust-src" "rust-analyzer"];
        };
        craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;
        craneLibLLvmTools = (crane.mkLib pkgs).overrideToolchain toolchainWithLLvmTools;

        src = let
          filterBySuffix = path: exts: lib.any (ext: lib.hasSuffix ext path) exts;
          sourceFilters = path: type: (craneLib.filterCargoSources path type) || filterBySuffix path [".c" ".h" ".hpp" ".cpp" ".cc"];
        in
          lib.cleanSourceWith {
            filter = sourceFilters;
            src = ./.;
          };
        commonArgs = rec {
          inherit src;
          pname = name;
          stdenv = p: p.clangStdenv;
          doCheck = false;
          nativeBuildInputs = with pkgs; [
            pkg-config
          ];
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;

          buildInputs = with pkgs;
            [
              vulkan-loader
            ]
            ++ (lib.optionals pkgs.stdenv.isLinux [
              alsa-lib-with-plugins
              libxkbcommon
              udev
              wayland
            ])
            ++ (lib.optionals pkgs.stdenv.isDarwin [
              libiconv
              apple-sdk_13
            ]);
        };
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

        packages = let
          pkg = craneLib.buildPackage (commonArgs
            // {inherit cargoArtifacts;}
            // {
              postInstall = ''
                mkdir -p $out/bin
                mkdir -p $out/share/bash-completions
                mkdir -p $out/share/fish/vendor_completions.d
                mkdir -p $out/share/zsh/site-functions
                $out/bin/${name} completions bash > $out/share/bash-completions/${name}.bash
                $out/bin/${name} completions fish > $out/share/fish/vendor_completions.d/${name}.fish
                $out/bin/${name} completions zsh > $out/share/zsh/site-functions/_${name}
              '';
            });
        in {
          "${name}" = pkg;
          default = pkg;
        };

        devShells = {
          default =
            pkgs.mkShell.override {
              stdenv = pkgs.clangStdenv;
              # stdenv =
              #   if pkgs.stdenv.isLinux
              #   then (pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv)
              #   else pkgs.clangStdenv;
            } (commonArgs
              // {
                packages = with pkgs;
                  [
                    toolchainWithRustAnalyzer
                    cargo-nextest
                    cargo-deny
                    cargo-expand
                    bacon
                    cargo-make
                    cargo-hack
                    cargo-outdated
                    lld
                  ]
                  ++ (lib.optionals pkgs.stdenv.isDarwin [
                    apple-sdk_13
                  ])
                  ++ (lib.optionals pkgs.stdenv.isLinux [
                    mold
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
