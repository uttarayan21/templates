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
      rust.lib = {
        path = ./rust/lib;
        description = "A simple rust library template using craneLib and rust-overlay";
      };
      rust.lib-ci = {
        path = ./rust/lib_ci;
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
