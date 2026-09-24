let
  npins = import ./npins;

  mkPackages = pkgs: {
    psyclyx-emacs =
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
        emacsWithPackages = epkgs.emacsWithPackages (
          ep: (import ./emacsPackages.nix ep) ++ [ combobulate ]
        );
      in
      # Wrapped emacs with config baked in, for iteration.
      pkgs.writeShellScriptBin "emacs-wrapped" ''
        ${emacsWithPackages}/bin/emacs --init-directory=${./config}
      '';
  };

  overlay = final: _prev: mkPackages final;
in
{
  sources ? npins,
  nixpkgs ? sources.nixpkgs,
  # External deps — one arg each, defaulting to this project's own pins.
  emacs-overlay ? sources.emacs-overlay,
  # emacs-unstable-pgtk comes from emacs-overlay; applied here so a standalone
  # build resolves it. When a superproject injects its own pkgs, emacs-overlay
  # is re-applied in the body below so the wrapped package still resolves.
  pkgs ? import nixpkgs { overlays = [ (import emacs-overlay) ]; },
  ...
}:
let
  # Body alias for the pin: `emacs-overlay` is the overlay's source;
  # emacsOverlay is the overlay itself.
  emacsOverlay = import emacs-overlay;
  finalPkgs = (pkgs.extend emacsOverlay).extend overlay;
in
{
  packages = mkPackages finalPkgs;
  inherit overlay;
  homeManagerModules.default = import ./hm-module.nix;
  default = finalPkgs.psyclyx-emacs;
  # Back-compat alias for the previous single `package` output.
  package = finalPkgs.psyclyx-emacs;
}
