;;; psyc-web.el --- Web development language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; HTML, CSS, JavaScript, TypeScript, JSX/TSX via web-mode and tree-sitter.
;;; Code:

(require 'psyc-lib)

;;;; JavaScript/TypeScript (tree-sitter)

(use-package js
  :ensure nil
  :defer t
  :mode ("\\.js\\'" . js-ts-mode)
  :init
  (gsetq js-indent-level 2))

(use-package typescript-ts-mode
  :ensure nil
  :defer t
  :mode ("\\.ts\\'" . typescript-ts-mode)
  :mode ("\\.tsx\\'" . tsx-ts-mode))

;;;; Web-mode (JSX, HTML templates, mixed content)

(use-package web-mode
  :mode ("\\.html\\'" "\\.erb\\'" "\\.hbs\\'" "\\.svelte\\'" "\\.vue\\'")
  :init
  (gsetq web-mode-markup-indent-offset 2
         web-mode-css-indent-offset 2
         web-mode-code-indent-offset 2
         web-mode-enable-auto-pairing t
         web-mode-enable-auto-closing t
         web-mode-enable-current-element-highlight t))

;;;; CSS

(use-package css-mode
  :ensure nil
  :defer t
  :mode ("\\.css\\'" . css-ts-mode)
  :init
  (gsetq css-indent-offset 2))

;;;; Emmet (HTML/CSS expansion)

(use-package emmet-mode
  :hook (web-mode css-mode css-ts-mode sgml-mode))

;;;; LSP for web languages

(with-eval-after-load 'eglot
  (dolist (mode '((js-ts-mode . ("typescript-language-server" "--stdio"))
                  (typescript-ts-mode . ("typescript-language-server" "--stdio"))
                  (tsx-ts-mode . ("typescript-language-server" "--stdio"))))
    (add-to-list 'eglot-server-programs mode)))

(add-hook 'js-ts-mode-hook #'eglot-ensure)
(add-hook 'typescript-ts-mode-hook #'eglot-ensure)
(add-hook 'tsx-ts-mode-hook #'eglot-ensure)

(provide 'psyc-web)
;;; psyc-web.el ends here
