;;; athame-lang-nix.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(use-package tramp
  :defer t
  :config
  (add-to-list 'tramp-remote-path "/run/current-system/sw/bin"))

(use-package nix-mode
  :mode "\\.nix\\'"
  :init
  (add-to-list 'auto-mode-alist
               (cons "/flake\\.lock\\'"
                     'js-json-mode)))

(use-package nix-repl
  :defer t)

(general-after 'nix-mode
  (general-def
    :keymaps 'nix-mode
    "f" #'nix-update-fetch
    "p" #'nix-format-buffer
    "r" #'nix-repl
    "s" #'nix-shell
    "b" #'nix-build
    "u" #'nix-unpack))


;;; Provide
(provide 'athame-lang-nix)
;;; athame-lang-nix.el ends here
