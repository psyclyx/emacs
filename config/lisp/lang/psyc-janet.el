;;; psyc-janet.el --- Janet language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package janet-mode
  :mode "\\.janet\\'"
  :hook ((janet-mode . smartparens-strict-mode)
         (janet-mode . evil-cleverparens-mode))
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(janet-mode "janet-lsp")))
  (with-eval-after-load 'apheleia
    (setf (alist-get 'janet-format apheleia-formatters) '("janet-format"))
    (setf (alist-get 'janet-mode apheleia-mode-alist) 'janet-format)))

(provide 'psyc-janet)
;;; psyc-janet.el ends here
