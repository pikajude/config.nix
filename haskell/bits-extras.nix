# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, gcc_s }:

cabal.mkDerivation (self: {
  pname = "bits-extras";
  version = "0.1.3";
  sha256 = "0sy9dksmdx0773bsn8yi5hw4qpgn16g8aqqj888w1x75cbsxr997";
  isLibrary = true;
  isExecutable = true;
  extraLibraries = [ gcc_s ];
  meta = {
    description = "Efficient high-level bit operations not found in Data.Bits";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
