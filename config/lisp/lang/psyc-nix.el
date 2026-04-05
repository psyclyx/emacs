;;; psyc-nix.el --- Nix language support -*- lexical-binding: t; -*-
;;; Code:

(require 'psyc-lib)

(use-package nix-mode
  :defer t
  :commands (nix-format-buffer nix-repl nix-shell nix-build nix-shell-unpack))

(use-package nix-ts-mode
  :mode "\\.nix\\'"
  :init
  (setq auto-mode-alist (rassq-delete-all 'nix-mode auto-mode-alist))
  (add-to-list 'auto-mode-alist
               (cons "/flake\\.lock\\'"
                     'js-json-mode))
  (general-after 'tramp
    (add-to-list 'tramp-remote-path "/run/current-system/sw/bin"))

  :config
  (unless psyc-vanilla-mode
    (general-def
      :keymaps 'nix-ts-mode-map
      :states 'normal
      :prefix "SPC m"
      "f" #'nix-format-buffer
      "r" #'nix-repl
      "s" #'nix-shell
      "b" #'nix-build
      "u" #'nix-shell-unpack)))

;; Modal local-leader
(with-eval-after-load 'psyc-modal
  (psyc-modal-localleader nix-ts-mode-hook "Nix"
    "f" #'nix-format-buffer
    "r" #'nix-repl
    "s" #'nix-shell
    "b" #'nix-build
    "u" #'nix-shell-unpack))

(provide 'psyc-nix)
;;; psyc-nix.el ends here
