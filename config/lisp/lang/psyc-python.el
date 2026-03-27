;;; psyc-python.el --- Python language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package python
  :ensure nil
  :defer t
  :mode ("\\.py\\'" . python-ts-mode)
  :hook (python-ts-mode . eglot-ensure)
  :init
  (gsetq python-indent-guess-indent-offset-verbose nil))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(python-ts-mode . ("pyright-langserver" "--stdio"))))

(provide 'psyc-python)
;;; psyc-python.el ends here
