;;; psyc-zig.el --- Zig language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package zig-mode
  :mode "\\.zig\\'"
  :hook (zig-mode . eglot-ensure)
  :init
  (gsetq zig-format-on-save nil))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(zig-mode . ("zls"))))

(with-eval-after-load 'apheleia
  (setf (alist-get 'zig-mode apheleia-mode-alist) 'zig-fmt)
  (setf (alist-get 'zig-fmt apheleia-formatters) '("zig" "fmt" "--stdin")))

(provide 'psyc-zig)
;;; psyc-zig.el ends here
