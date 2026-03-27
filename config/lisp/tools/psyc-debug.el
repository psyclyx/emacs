;;; psyc-debug.el --- Debug Adapter Protocol support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package dap-mode
  :defer t
  :init
  (gsetq dap-auto-configure-features '(sessions locals breakpoints expressions controls tooltip)))

(provide 'psyc-debug)
;;; psyc-debug.el ends here
