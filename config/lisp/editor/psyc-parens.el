;;; psyc-parens.el --- Structural editing -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

;;;; Electric pair (auto-pairing for all modes)

(use-package elec-pair
  :ensure nil
  :hook (emacs-startup . electric-pair-mode))

;;;; Smartparens + evil-cleverparens (structural editing for lisps)

(use-package smartparens
  :defer t
  :hook (emacs-lisp-mode . smartparens-strict-mode)
  :config
  (require 'smartparens-config))

(use-package evil-cleverparens
  :defer t
  :hook (emacs-lisp-mode . evil-cleverparens-mode)
  :init
  (gsetq evil-cleverparens-swap-move-by-word-and-symbol t))

(provide 'psyc-parens)
;;; psyc-parens.el ends here
