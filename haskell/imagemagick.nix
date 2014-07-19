{ cabal, HUnit, ImageMagick, liftedBase
, MonadCatchIOTransformers, QuickCheck, resourcet, systemFilepath
, testFramework, testFrameworkHunit, testFrameworkQuickcheck2, text
, transformers, vector
}:

cabal.mkDerivation (self: {
  pname = "imagemagick";
  version = "0.0.3.5";
  sha256 = "0vwmx86wpxr1f5jrwlqpvrb94dbrm0jjdqq6bppfnfyppd3s1mmq";
  isLibrary = true;
  isExecutable = true;
  buildDepends = [
    MonadCatchIOTransformers resourcet systemFilepath text transformers
    vector
  ];
  testDepends = [
    HUnit ImageMagick liftedBase QuickCheck resourcet
    systemFilepath testFramework testFrameworkHunit
    testFrameworkQuickcheck2 text transformers vector
  ];
  pkgconfigDepends = [ ImageMagick ];
  doCheck = false;
  meta = {
    description = "bindings to imagemagick library";
    license = "unknown";
    platforms = self.ghc.meta.platforms;
  };
})
