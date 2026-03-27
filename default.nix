{ sources ? import ./npins
, pkgs ? import sources.nixpkgs {
    overlays = [ (import sources.emacs-overlay) ];
  }
}:

let
  emacs = pkgs.emacs-unstable-pgtk;
  epkgs = pkgs.emacsPackagesFor emacs;
  combobulate = epkgs.trivialBuild {
    pname = "combobulate";
    version = "0-unstable";
    src = pkgs.fetchFromGitHub {
      owner = "mickeynp";
      repo = "combobulate";
      rev = "38773810b5e532f25d11c6d1af02c3a8dffeacd7";
      hash = "sha256-gW0j0asfH4My+mBSt8pj3d51PigGWzFUhETydUI9xEg=";
    };
  };
  emacsWithPackages = epkgs.emacsWithPackages (ep:
    (import ./emacsPackages.nix ep) ++ [ combobulate ]);
in
{
  # Wrapped emacs with config baked in, for iteration
  package = pkgs.writeShellScriptBin "emacs-wrapped" ''
    ${emacsWithPackages}/bin/emacs --init-directory=${./config}
  '';

}
