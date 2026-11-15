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
        camel-snake-kebab = pkgs.fetchurl {
          url = "https://repo.clojars.org/camel-snake-kebab/camel-snake-kebab/0.4.3/camel-snake-kebab-0.4.3.jar";
          hash = "sha256-gZHzNXdjENeFekCtMyVL5mrbNjgGsYE22IQxlpI6wsg=";
        };
        cuerdas = pkgs.fetchurl {
          url = "https://repo.clojars.org/funcool/cuerdas/2026.415/cuerdas-2026.415.jar";
          hash = "sha256-Cj5FToYWnHdHd50uVgovDJ+jcDO048Fgv1VOqBOWa38=";
        };
        clojure-string-oracle = pkgs.writeShellApplication {
          name = "clojure-string-oracle";
          runtimeInputs = [ pkgs.babashka ];
          text = ''
            exec bb --classpath ${camel-snake-kebab}:${cuerdas} ${./test/oracle/clojure_string.clj} "$@"
          '';
        };
      in
      {
        packages = rainix.packages.${system} // {
          inherit clojure-string-oracle;
        };
        devShells = rainix.devShells.${system};
      }
    );

}
