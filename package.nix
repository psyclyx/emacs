{ emacsPackagesFor, emacs }:
let
  deps =
    epkgs: with epkgs; [
      better-jumper
      cape
      centaur-tabs
      consult
      consult-eglot
      corfu
      direnv
      envrc
      evil
      evil-collection
      evil-easymotion
      evil-nerd-commenter
      evil-snipe
      evil-surround
      evil-textobj-anyblock
      exato
      general
      git-gutter-fringe
      magit
      marginalia
      nerd-icons
      nerd-icons-completion
      nerd-icons-corfu
      nix-mode
      orderless
      smartparens
      vertico
      ws-butler
    ];
in
(emacsPackagesFor emacs).emacsWithPackages deps
