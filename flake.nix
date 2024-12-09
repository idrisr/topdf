{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, flake-utils, ... }:
    let
      compiler = "ghc965";
      docker = pkgs.dockerTools.buildImage {
        name = "topdf";
        config = { Cmd = [ "${topdf}/bin/topdf" ]; };
      };
      pkgs = nixpkgs.legacyPackages.${system};
      system = flake-utils.lib.system.x86_64-linux;
      topdf = pkgs.haskell.packages.${compiler}.callCabal2nix "" ./topdf { };
      topdfW = pkgs.stdenvNoCC.mkDerivation {
        meta.mainProgram = "topdf";
        name = "topdf";
        pname = "topdf";
        dontUnpack = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        installPhase = ''
          mkdir -p "$out/bin"
          cp ${topdf}/bin/topdf $out/bin/topdf
          wrapProgram $out/bin/topdf --set PATH ${
            pkgs.lib.makeBinPath [ pkgs.imagemagick ]
          }
        '';
      };
    in {
      packages.${system} = {
        default = topdfW;
        inherit docker;
      };
    };
}
