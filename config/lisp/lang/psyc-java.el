;;; psyc-java.el --- Java language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package java-ts-mode
  :ensure nil
  :defer t
  :mode ("\\.java\\'")
  :hook (java-ts-mode . eglot-ensure))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(java-ts-mode . ("jdtls"))))

(provide 'psyc-java)
;;; psyc-java.el ends here
