{
  description = ''
    A opinionated, simple(?) nix flake
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
      clang = {
        path = ./clang;
        description = "A simple clang template";
      };
    };
  };
}
