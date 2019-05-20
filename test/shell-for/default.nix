{ stdenv, cabal-install, mkStackSnapshotPkgSet, mkCabalProjectPkgSet }:

with stdenv.lib;

let
  pkgSet = {
    stack = mkStackSnapshotPkgSet {
      resolver = "lts-12.21";
      # Work around a mismatch between stackage metadata and the
      # libraries shipped with GHC.
      # https://github.com/commercialhaskell/stackage/issues/4466
      pkg-def-extras = [(hackage: {
        packages = {
          "transformers" = (((hackage.transformers)."0.5.6.2").revisions).default;
          "process" = (((hackage.process)."1.6.5.0").revisions).default;
        };
      })];
    };

    cabal = mkCabalProjectPkgSet {
      plan-pkgs = import ./pkgs.nix;
      pkg-def-extras = [{
        pkga = ./.plan.nix/pkga.nix;
        pkgb = ./.plan.nix/pkgb.nix;
      }];
    };
  };

  env = {
    stack = pkgSet.stack.config.hsPkgs.shellFor {
      packages = ps: with ps; [ conduit conduit-extra resourcet ];
      withHoogle = true;
      # This adds cabal-install to the shell, which helps tests because
      # they use a nix-shell --pure. Normally you would BYO cabal-install.
      buildInputs = [ cabal-install ];
    };

    cabal = pkgSet.cabal.config.hsPkgs.shellFor {
      packages = ps: with ps; [ pkga pkgb ];
    };
  };

in
  stdenv.mkDerivation {
    name = "shell-for-test";

    buildCommand = ''
      ########################################################################
      # test shell-for with an example program

      printf "checking that the shell env has the dependencies...\n" >& 2
      ${env.stack.ghc}/bin/runghc ${./pkgb/src/conduit.hs}

      touch $out
    '';

    meta.platforms = platforms.all;
    passthru = {
      # Used for debugging with nix repl
      inherit pkgSet;
      # Used for testing externally with nix-shell (../tests.sh).
      inherit env;
    };
}
