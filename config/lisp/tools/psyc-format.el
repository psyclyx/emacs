;;; psyc-format.el --- Code formatting -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(defcustom psyc-format-on-save-disabled-modes
  '(org-msg-edit-mode) "Don't format on these modes"
  :type '(list symbol))

(defun psyc-format--inhibit-p ()
  (or (eq major-mode 'fundamental-mode)
      (string-blank-p (buffer-name))
      (eq psyc-format-on-save-disabled-modes t)
      (not (null (memq major-mode psyc-format-on-save-disabled-modes)))))

(use-package apheleia
  :defer t
  :ghook
  'prog-mode-hook 'text-mode-hook 'conf-mode-hook
  ('apheleia-inhibit-functions #'psyc-format--inhibit-p)

  :config
  (add-to-list 'apheleia-mode-alist '(sh-mode . shfmt))
  (add-to-list 'apheleia-mode-alist '(bash-ts-mode . shfmt))

  ;; Web languages via prettier
  (dolist (mode '(js-ts-mode typescript-ts-mode tsx-ts-mode
                  css-ts-mode web-mode json-ts-mode yaml-mode
                  markdown-mode))
    (add-to-list 'apheleia-mode-alist (cons mode 'prettier)))
  (add-to-list 'apheleia-formatters '(lsp . eglot-format-buffer))

  (setf (alist-get 'nix-mode apheleia-formatters) '("nixfmt" "-s"))

  (add-to-list 'apheleia-mode-alist '(cuda-mode . clang-format))
  (add-to-list 'apheleia-mode-alist '(protobuf-mode . clang-format))
  (add-to-list 'apheleia-formatters-mode-extension-assoc '(cuda-mode . ".cu"))
  (add-to-list 'apheleia-formatters-mode-extension-assoc '(protobuf-mode . ".proto"))

  (setf (alist-get 'clang-format apheleia-formatters)
        `("clang-format"
          "-assume-filename"
          (or (apheleia-formatters-local-buffer-file-name)
              (apheleia-formatters-mode-extension)
              ".c")
          (when apheleia-formatters-respect-indent-level
            (unless (locate-dominating-file default-directory ".clang-format")
              (format "--style={IndentWidth: %d}" c-basic-offset))))))

(provide 'psyc-format)
;;; psyc-format.el ends here
