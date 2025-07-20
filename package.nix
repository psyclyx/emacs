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
      treesit-grammars.with-all-grammars
      vertico
      ws-butler
      zig-mode
    ];
in
(emacsPackagesFor (emacs.override { withTreeSitter = true; })).emacsWithPackages deps
