{ sources ? import ./npins }:
{ config, lib, pkgs, ... }:
let
  emacsOverlay = import sources.emacs-overlay;
  emacsPkgs = pkgs.extend emacsOverlay;
  emacs = emacsPkgs.emacs-unstable-pgtk;

  spork = pkgs.callPackage ./packages/spork.nix {};
  janet-lsp = pkgs.callPackage ./packages/janet-lsp.nix { inherit spork; };
in
{
  options.psyclyx-emacs.enable = lib.mkEnableOption "Emacs config";
  config = lib.mkIf config.psyclyx-emacs.enable {
    programs.emacs = {
      enable = true;
      package = emacs;
      extraPackages = import ./emacsPackages.nix;
    };
    services.emacs = {
      enable = true;
      defaultEditor = true;
      client.enable = true;
    };
    home.file.".config/emacs" = {
      source = ./config;
      recursive = true;
    };
    home.packages = [
      pkgs.janet
      pkgs.nerd-fonts.symbols-only  # NFM.ttf for nerd-icons
      spork                         # provides janet-format
      janet-lsp
    ];
  };
}
