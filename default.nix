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

  homeManagerModule =
    { config, lib, pkgs, ... }:
    {
      options.psyclyx-emacs.enable = lib.mkEnableOption "Emacs config";
      config = lib.mkIf config.psyclyx-emacs.enable {
        programs.emacs = {
          enable = true;
          package = emacs;
          extraPackages = import ./emacsPackages.nix;
        };
        home.file.".config/emacs" = {
          source = ./config;
          recursive = true;
        };
      };
    };
}
