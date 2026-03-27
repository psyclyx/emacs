;;; psyc-check.el --- Syntax checking -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package flymake
  :defer t
  :hook (prog-mode text-mode)
  :init
  (gsetq flymake-show-diagnostics-at-end-of-line t)
  :general-config
  (:keymaps 'flymake-mode-map
   :states '(normal visual)
   "]d" #'flymake-goto-next-error
   "[d" #'flymake-goto-prev-error))

(provide 'psyc-check)
;;; psyc-check.el ends here
