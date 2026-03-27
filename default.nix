{ sources ? import ./npins
, pkgs ? import sources.nixpkgs {
    overlays = [ (import sources.emacs-overlay) ];
  }
}:

let
  emacs = pkgs.emacs-unstable-pgtk;
  emacsWithPackages = (pkgs.emacsPackagesFor emacs).emacsWithPackages (import ./emacsPackages.nix);
in
{
  # Wrapped emacs with config baked in, for iteration
  package = pkgs.writeShellScriptBin "emacs-wrapped" ''
    ${emacsWithPackages}/bin/emacs --init-directory=${./config}
  '';

}
