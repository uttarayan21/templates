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

  outputs = {self, ...}: {
    templates = {
      rust.crate = {
        path = ./rust/main;
        description = "A simple rust template using craneLib and rust-overlay";
      };
      rust.cli = {
        path = ./rust/cli;
        description = "A simple rust template using craneLib and rust-overlay";
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
      python = {
        path = ./python/default;
        description = "A simple python template";
      };
      atopile = {
        path = ./python/atopile;
        description = "A atopile template";
      };
    };
  };
}
