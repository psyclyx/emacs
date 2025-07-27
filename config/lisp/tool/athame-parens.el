;;; athame-parens.el --- foo -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package smartparens
  :hook ((prog-mode . smartparens-mode)
         (emacs-lisp-mode . smartparens-strict-mode))
  :custom
  (sp-show-pair-delay 0.125)
  (sp-show-pair-from-inside t))

(use-package evil-cleverparens
  :hook (emacs-lisp-mode . evil-cleverparens-mode)
  :custom
  (evil-cleverparens-swap-move-by-word-and-symbol t))

;;;; Provide
(provide 'athame-parens)
;;; athame-parens.el ends here
