;;; psyc-data.el --- Data/config file format support -*- lexical-binding: t; -*-
;;; Commentary:
;;; JSON, YAML, TOML, Markdown.
;;; Code:

(require 'psyc-lib)

;;;; JSON (tree-sitter)

(use-package json-ts-mode
  :ensure nil
  :defer t
  :mode ("\\.json\\'" "\\.jsonc\\'")
  :init
  (gsetq json-ts-mode-indent-offset 2))

;;;; YAML

(use-package yaml-mode
  :mode ("\\.ya?ml\\'"))

;;;; TOML

(use-package toml-mode
  :mode ("\\.toml\\'"))

;;;; Markdown

(use-package markdown-mode
  :mode ("\\.md\\'" "\\.markdown\\'")
  :init
  (gsetq markdown-fontify-code-blocks-natively t
         markdown-command "markdown"
         markdown-header-scaling t))

(provide 'psyc-data)
;;; psyc-data.el ends here
