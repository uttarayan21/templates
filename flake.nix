{
  description = ''
    A few nix flake templates for different languages and use cases
  '';
  outputs = {self}: {
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
        path = ./rust/cli;
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
      frontend = {
        path = ./frontend;
        description = "A simple frontend template with yarn and nodejs";
      };
      clang = {
        path = ./clang;
        description = "A simple clang template";
      };
    };
  };
}
