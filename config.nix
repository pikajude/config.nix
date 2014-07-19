{ pkgs }:

{
  packageOverrides = pkgs: with pkgs; rec {
    bundler = lib.overrideDerivation rubyLibs.bundler (oldAttrs: { dontPatchShebangs = 1; });

    nix = lib.overrideDerivation pkgs.nixUnstable (oldAttrs: {
      src = pkgs.fetchgit {
        url = "https://github.com/joelteon/nix.git";
        rev = "refs/heads/master";
        sha256 = "0rgm8p7awvh1khl5w2w2ynw2py93d8pqqkay8grz0klk87jfgach";
      };

      buildInputs = oldAttrs.buildInputs ++ (with pkgs; [
        autoconf automake bison flex libxml2 libxslt w3m
      ]);

      preConfigure = ''
        ./bootstrap.sh
      '';

      makeFlags = "${oldAttrs.makeFlags} docbookxsl=${pkgs.docbook5_xsl}/xml/xsl/docbook docbookrng=${pkgs.docbook5_xsl}/xml/xsl/docbook/slides/schema/relaxng";
    });

    platform = pkgs.callPackage ../../.dev/platform/developer-portal {
      self = pkgs.pythonPackages;
      overrides = {};
    };

    platformEnv = let
      platformDeps = with platform; [
        cryptography six cffi django python-memcached django-sslserver requests pycparser
      ];
      py = x: "${x}/lib/python2.7/site-packages";
      platformPath = pkgs.lib.foldl (x: y: "${x}:${py y}") (py platform.pyauth) platformDeps;
    in pkgs.myEnvFun {
      name = "platform";
      shell = "${pkgs.zsh}/bin/zsh";
      buildInputs = [ platform.fabric ruby bundler ];
      extraCmds = with platform; ''
        export PYTHONPATH=${platformPath}
      '';
    };

    overrideCabal = hp: pkg: f: pkg.override {
      cabal = hp.cabal.override {
        extension = a: b: f a b;
      };
    };

    ghcEnv = myghc: ghcPkgsPre: myname:
      let
        ghcpkgs = ghcPkgsPre.override {
          extension = self: hp: {
            airbrake = hp.callPackage ./haskell/airbrake.nix {};
            hs_imagemagick = hp.callPackage ./haskell/imagemagick.nix {
              ImageMagick = pkgs.imagemagick;
            };
            markdown = hp.callPackage ./haskell/markdown.nix {};
            scan = hp.callPackage ./haskell/scan.nix {};
            stmLifted = hp.callPackage ./haskell/stm-lifted.nix {};
            systemFileio = hp.disableTest hp.systemFileio;
            textNormal = hp.disableTest (hp.callPackage ./haskell/text-normal.nix {});
            thyme = overrideCabal hp hp.thyme (a: b: {
              buildTools = [ hp.cpphs ];
            });
            yesodPagination = hp.disableTest (hp.callPackage ./haskell/yesod-pagination.nix {});
            yesodWebsockets = hp.callPackage ./haskell/yesod-websockets.nix {};
          };
        };
      in pkgs.myEnvFun {
      name = myname;
      shell = "${pkgs.zsh}/bin/zsh";
      buildInputs = [
        stdenv
        myghc
        coreutils
        pkgs.rubyLibs.dotenv
      ] ++ (with ghcpkgs; [
        cabalInstall_1_20_0_3
        ghcMod
        scan
        lens
        machines
        netwire
      ] ++ [
        # stuff for narwhal
        MonadRandom
        airbrake
        aws
        conduitCombinators
        hs_imagemagick
        markdown
        persistentPostgresql
        processExtras
        pwstoreFast
        stmLifted
        textNormal
        thyme
        vault
        vectorSpace
        wai
        waiExtra
        waiLogger
        warp
        yaml
        yesod
        yesodAuth
        yesodBin
        yesodCore
        yesodPagination
        yesodStatic
        yesodWebsockets
      ]) ++ (with nodePackages; [ uglify-js coffee-script ]);
    };

    ghc76 = ghcEnv ghc.ghc763 haskellPackages_ghc763 "ghc76";
    ghc78 = ghcEnv ghc.ghc783 haskellPackages_ghc783 "ghc78";
    ghcHEAD = ghcEnv ghc.ghcHEAD haskellPackages_ghcHEAD "ghcHEAD";
  };
}
