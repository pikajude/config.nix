{ pkgs }:

{
  packageOverrides = pkgs: with pkgs; rec {
    bundler = lib.overrideDerivation rubyLibs.bundler (oldAttrs: { dontPatchShebangs = 1; });

    addRoots = pkgs.callPackage ../argo/add-roots {};

    tmux = lib.overrideDerivation pkgs.tmux (oldAttrs: {
      name = "tmux-1.9a";
      src = fetchurl {
        url = "mirror://sourceforge/tmux/tmux-1.9a.tar.gz";
        sha256 = "1x9k4wfd4l5jg6fh7xkr3yyilizha6ka8m5b1nr0kw8wj0mv5qy5";
      };
    });

    ruby = pkgs.callPackage ./ruby/2.1.nix {};

    forumEnv = pkgs.myEnvFun {
      name = "forum";
      shell = "${pkgs.zsh}/bin/zsh";
      buildInputs = [ nodejs bundler ruby ];
    };

    portal = pkgs.callPackage ../../.dev/platform/developer-portal {
      self = pkgs.pythonPackages;
      overrides = {};
    };

    portalEnv = let
      portalDeps = with portal; [
        cryptography six cffi django python-memcached django-sslserver requests pycparser
      ];
      py = x: "${x}/lib/python2.7/site-packages";
      portalPath = pkgs.lib.foldl (x: y: "${x}:${py y}") (py portal.pyauth) portalDeps;
    in pkgs.myEnvFun {
      name = "portal";
      shell = "${pkgs.zsh}/bin/zsh";
      buildInputs = [ portal.fabric ruby bundler pythonPackages.pip ];
      extraCmds = with portal; ''
        export PYTHONPATH=${portalPath}
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
            snapLoaderDynamic = overrideCabal hp hp.snapLoaderDynamic (a: b: {
              jailbreak = true;
            });
            snapletSass = overrideCabal hp (hp.callPackage ./haskell/snaplet-sass.nix {})
              (a: b: { jailbreak = true; });
            srcWatch = hp.callPackage /Users/joelteon/.dev/Haskell/src-watch {};
            stmLifted = hp.callPackage ./haskell/stm-lifted.nix {};
            systemFileio = hp.disableTest hp.systemFileio;
            textNormal = hp.disableTest (hp.callPackage ./haskell/text-normal.nix {});
            thyme = overrideCabal hp hp.thyme (a: b: {
              buildTools = [ hp.cpphs ];
            });
            webRoutesTh = hp.callPackage ./haskell/web-routes-th.nix {};
            yesodBin = hp.callPackage /Users/joelteon/.dev/Haskell/yesod/yesod-bin {};
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
        bytestringTrie
        cabalInstall_1_20_0_3
        ghcMod
        Glob
        fsnotify
        scan
        srcWatch
        lens
        machines
        netwire
        options
        plugins
      ] ++ [
        # stuff for snap narwhal
        # snap
        # snapLoaderDynamic
        # snapLoaderStatic
        # snapWebRoutes
        # snapletSass
        # webRoutesTh

        # rubyLibs.sass
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

    plistService = callPackage ./system/plist-service.nix {};


    ###########################################################
    # muh services
    ###########################################################
    dataDir = "/nix/data";

    serviceNginx = plistService {
      name = "nginx";
      programArgs = [ "${nginx}/bin/nginx" "-g" "daemon off;" "-p" dataDir ];
      keepAlive = true;
      runAtLoad = true;
      stdout = "${dataDir}/var/log/nginx.log";
      stderr = "${dataDir}/var/log/nginx.log";
    };

    serviceMysql = plistService {
      name = "mysql";
      programArgs = [
        "${mysql55}/bin/mysqld_safe"
        "--bind-address=127.0.0.1"
        "--datadir=${dataDir}/var/mysql"
      ];
      keepAlive = true;
      runAtLoad = true;
      workingDirectory = "${dataDir}/var";
      stdout = "${dataDir}/var/log/mysql.log";
      stderr = "${dataDir}/var/log/mysql.log";
    };

    serviceRedis = plistService {
      name = "redis";
      programArgs = [ "${redis}/bin/redis-server" "${dataDir}/etc/redis.conf" ];
      keepAlive = true;
      runAtLoad = true;
      workingDirectory = "${dataDir}/var";
      stdout = "${dataDir}/var/log/redis.log";
      stderr = "${dataDir}/var/log/redis.log";
    };

    servicePostgresql = plistService {
      name = "postgresql";
      programArgs = [
        "${postgresql93}/bin/postgres"
        "-D" "${dataDir}/var/postgres"
        "-r" "${dataDir}/var/postgres/server.log"
      ];
      keepAlive = true;
      runAtLoad = true;
      workingDirectory = "${dataDir}/var/postgres";
      stdout = "${dataDir}/var/postgres/server.log";
      stderr = "${dataDir}/var/postgres/server.log";
    };
  };
}
