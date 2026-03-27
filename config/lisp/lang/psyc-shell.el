;;; psyc-shell.el --- Shell script support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package sh-script
  :ensure nil
  :defer t
  :mode ("\\.sh\\'" . bash-ts-mode)
  :mode ("\\.bash\\'" . bash-ts-mode)
  :hook (bash-ts-mode . eglot-ensure))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(bash-ts-mode . ("bash-language-server" "start"))))

(provide 'psyc-shell)
;;; psyc-shell.el ends here
