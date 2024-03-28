{
  description = ''
    A opinionated, simple(?) nix flake
  '';
  outputs = {self}: {
    templates = {
      rust = {
        path = ./rust;
        description = "A simple rust template using craneLib and rust-overlay";
      };
    };
  };
}
