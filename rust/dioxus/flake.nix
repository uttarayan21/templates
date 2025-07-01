{
  description = "A simple rust flake using rust-overlay and craneLib";

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
        # cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
        # name = cargoToml.package.name;
        name = "darksailor.dev";
        crates = crates-nix.mkLib {inherit pkgs;};
        dioxus-cli = with pkgs; (crates.buildCrate "dioxus-cli" {
          buildFeatures = [
            "no-downloads"
            "optimizations"
          ];

          nativeBuildInputs = [
            pkg-config
            cacert
          ];

          buildInputs = [openssl];
          OPENSSL_NO_VENDOR = 1;

          checkFlags = [
            # requires network access
            "--skip=serve::proxy::test"
            "--skip=wasm_bindgen::test"
          ];
          postPatch = ''
            substituteInPlace $cargoDepsCopy/wasm-opt-sys-*/build.rs \
              --replace-fail 'check_cxx17_support()?;' '// check_cxx17_support()?;'
          '';
          nativeCheckInputs = [rustfmt];
        });

        stableToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = ["wasm32-unknown-unknown" "x86_64-unknown-linux-gnu"];
        };
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
            stdenv = pkgs.clangStdenv;
            doCheck = false;
            # LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
            # nativeBuildInputs = with pkgs; [
            #   cmake
            #   llvmPackages.libclang.lib
            # ];
            buildInputs = with pkgs;
              []
              ++ (lib.optionals pkgs.stdenv.isLinux [
                at-spi2-atk
                atkmm
                cairo
                gdk-pixbuf
                glib
                gtk3
                harfbuzz
                librsvg
                libsoup_3
                pango
                webkitgtk_4_1
                openssl
                xdotool
              ])
              ++ (lib.optionals pkgs.stdenv.isDarwin [
                libiconv
                apple-sdk_13
              ]);

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];
            # GDK_BACKEND = "x11";
            WEBKIT_DISABLE_DMABUF_RENDERER = 1; # Again NVIDIA things.
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
          default = pkgs.mkShell.override {stdenv = pkgs.clangStdenv;} (commonArgs
            // {
              packages = with pkgs;
                [
                  stableToolchainWithRustAnalyzer
                  cargo-nextest
                  cargo-deny
                  dioxus-cli
                  wasm-bindgen-cli
                ]
                ++ (lib.optionals pkgs.stdenv.isDarwin [
                  apple-sdk_13
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
