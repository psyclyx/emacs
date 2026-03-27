;;; psyc-zig.el --- Zig language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package zig-ts-mode
  :mode "\\.zig\\'"
  :hook (zig-ts-mode . eglot-ensure))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(zig-ts-mode . ("zls"))))

(with-eval-after-load 'apheleia
  (setf (alist-get 'zig-ts-mode apheleia-mode-alist) 'zig-fmt)
  (setf (alist-get 'zig-fmt apheleia-formatters) '("zig" "fmt" "--stdin")))

(provide 'psyc-zig)
;;; psyc-zig.el ends here
