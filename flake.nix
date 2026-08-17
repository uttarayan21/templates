{
  description = ''
    A few nix flake templates for different languages and use cases
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    nix-github-actions = {
      url = "github:uttarayan21/nix-github-actions";
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

  outputs = {self, ...}: rec {
    templates = {
      rust.cli = {
        path = ./rust/cli;
        description = "A simple rust template using craneLib and rust-overlay";
      };
      rust.crates = {
        path = ./rust/crates;
        description = "A simple rust template using craneLib, rust-overlay and crates.nix";
      };
      rust.wasm = {
        path = ./rust/wasm;
        description = "A rust wasm template using craneLib and rust-overlay";
      };
      rust.bevy = {
        path = ./rust/bevy;
        description = "A simple rust template using craneLib and rust-overlay for bevy";
      };
      rust.sys = {
        path = ./rust/sys;
        description = "A simple rust template using craneLib and rust-overlay";
      };
      rust.lib = {
        path = ./rust/lib;
        description = "A simple rust library template using craneLib and rust-overlay with Github Actions CI";
      };
      rust.dioxus = {
        path = ./rust/dioxus;
        description = "Dioxus template using craneLib and rust-overlay";
      };
      frontend = {
        path = ./frontend;
        description = "A simple frontend template with yarn and nodejs";
      };
      clang = {
        path = ./clang;
        description = "A simple clang template";
      };
      shell = {
        path = ./shell;
        description = "A simple shell devshell template";
      };
      python = {
        path = ./python/default;
        description = "A simple python template";
      };
      atopile = {
        path = ./python/atopile;
        description = "A atopile template";
      };
    };

    # `om init` template registry.
    # https://omnix.page/om/init.html#spec
    #
    # Every template here is also a plain `nix flake init -t` template above;
    # the extra `params` are what let `om init` substitute the placeholder
    # names instead of you search-replacing them by hand.
    om.templates = let
      # The rust templates all ship a crate literally named `hello`. The flake
      # reads the name back out of Cargo.toml, so replacing it there also fixes
      # every derivation name; the workflow files hardcode it and need the same
      # substitution.
      packageName = {
        name = "package-name";
        description = "Name of the Rust package";
        placeholder = "hello";
      };
      githubCI = {
        name = "github-ci";
        description = "Include GitHub Actions workflow configuration";
        paths = [".github"];
        value = true;
      };
      # Scaffold-only assertions: cheap, run on every system.
      sourceTest = params: source: {
        default = {
          inherit params;
          asserts.source = source;
        };
      };
      rust = template: {
        inherit template;
        params = [packageName githubCI];
        tests = sourceTest {package-name = "qux";} {
          "Cargo.toml" = true;
          "flake.nix" = true;
          ".github/workflows/build.yaml" = true;
        };
      };
      bare = template: {
        inherit template;
        params = [];
      };
    in {
      rust-cli = rust templates.rust.cli;
      rust-crates = rust templates.rust.crates;
      rust-wasm = rust templates.rust.wasm;
      rust-bevy = rust templates.rust.bevy;
      rust-sys = rust templates.rust.sys;
      rust-lib = rust templates.rust.lib;
      # No .github and no Cargo.toml; the name is hardcoded in its flake.
      rust-dioxus = {
        template = templates.rust.dioxus;
        params = [
          {
            name = "package-name";
            description = "Name of the Rust package";
            placeholder = "darksailor.dev";
          }
        ];
      };
      frontend = bare templates.frontend;
      clang = bare templates.clang;
      shell = bare templates.shell;
      python = bare templates.python;
      atopile = bare templates.atopile;
    };
  };
}
