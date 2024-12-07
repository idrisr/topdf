{ pkgs, ... }:
let compiler = "ghc965";
in {
  packages = with pkgs.haskell.packages."${compiler}"; [
    fourmolu
    cabal-fmt
    implicit-hie
  ];

  languages.haskell.enable = true;
}
