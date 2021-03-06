# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, HUnit, parsec, QuickCheck, split, testFramework
, testFrameworkHunit, testFrameworkQuickcheck2, testFrameworkTh
, text, webRoutes
}:

cabal.mkDerivation (self: {
  pname = "web-routes-th";
  version = "0.22.2";
  sha256 = "1dk768m0bb4y3i1q9sxj2fbn6farlyyy52fxmk0ipbnbdq7if71f";
  buildDepends = [ parsec split text webRoutes ];
  testDepends = [
    HUnit QuickCheck testFramework testFrameworkHunit
    testFrameworkQuickcheck2 testFrameworkTh webRoutes
  ];
  meta = {
    description = "Support for deriving PathInfo using Template Haskell";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
