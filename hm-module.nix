{ sources ? import ./npins }:
{ config, lib, pkgs, ... }:
let
  emacsOverlay = import sources.emacs-overlay;
  emacsPkgs = pkgs.extend emacsOverlay;
  emacs = emacsPkgs.emacs-unstable-pgtk;
  cfg = config.psyclyx-emacs;
in
{
  options.psyclyx-emacs = {
    enable = lib.mkEnableOption "Emacs config";
    anthropicKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to file containing Anthropic API key (read at Emacs startup)";
    };
    openrouterKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to file containing OpenRouter API key (read at Emacs startup)";
    };
  };
  config = lib.mkIf cfg.enable {
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
      pkgs.nerd-fonts.symbols-only  # NFM.ttf for nerd-icons
    ];
    home.sessionVariables =
      lib.optionalAttrs (cfg.anthropicKeyFile != null) {
        EMACS_ANTHROPIC_KEY_FILE = toString cfg.anthropicKeyFile;
      } // lib.optionalAttrs (cfg.openrouterKeyFile != null) {
        EMACS_OPENROUTER_KEY_FILE = toString cfg.openrouterKeyFile;
      };
  };
}
