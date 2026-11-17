{
  description = "Flake for development workflows.";

  inputs = {
    rainix.url = "github:rainlanguage/rainix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { flake-utils, rainix, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = rainix.pkgs.${system};
        rust-string-oracle = pkgs.rustPlatform.buildRustPackage {
          pname = "rust-string-oracle";
          version = "0.1.0";
          src = ./test/oracle;
          cargoLock.lockFile = ./test/oracle/Cargo.lock;
        };
      in
      {
        packages = rainix.packages.${system} // {
          inherit rust-string-oracle;
        };
        devShells = rainix.devShells.${system};
      }
    );

}
