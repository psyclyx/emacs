;;; psyc-parens.el --- Structural editing -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

;;;; Smartparens

(use-package smartparens
  :defer t
  :hook ((prog-mode . smartparens-mode)
         (emacs-lisp-mode . smartparens-strict-mode))
  :init
  (gsetq sp-show-pair-delay 0.125
	 sp-show-pair-from-inside t)
  (require 'smartparens-config))

;;;; Evil-cleverparens

(use-package evil-cleverparens
  :defer t
  :hook (emacs-lisp-mode . evil-cleverparens-mode)
  :init
  (gsetq evil-cleverparens-swap-move-by-word-and-symbol t))

(provide 'psyc-parens)
;;; psyc-parens.el ends here
