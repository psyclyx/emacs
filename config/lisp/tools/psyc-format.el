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

(defun psyc-format--update-web-mode-h ()
  (when (eq major-mode 'web-mode)
    (setq web-mode-fontification-off nil)
    (when (and web-mode-scan-beg web-mode-scan-end global-font-lock-mode)
      (save-excursion
        (font-lock-fontify-region web-mode-scan-beg web-mode-scan-end)))))

(use-package apheleia
  :defer t
  :ghook
  'prog-mode-hook 'text-mode-hook 'conf-mode-hook
  ('apheleia-inhibit-functions #'psyc-format--inhibit-p)
  ('apheleia-post-format-hook #'psyc-format--update-web-mode-h)

  :config
  (add-to-list 'apheleia-mode-alist '(sh-mode . shfmt))
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
              (format "--style={IndentWidth: %d}" c-basic-offset)))))

  ;; Respect prettier settings (from doom)
  (dolist (formatter '(prettier prettier-css prettier-html prettier-javascript
                                prettier-json prettier-scss prettier-svelte
                                prettier-typescript prettier-yaml))
    (setf (alist-get formatter apheleia-formatters)
          (append (delete '(apheleia-formatters-js-indent "--use-tabs" "--tab-width")
                          (alist-get formatter apheleia-formatters))
                  '((when apheleia-formatters-respect-indent-level
                      (unless (or (cl-loop for file
                                           in '(".prettierrc"
                                                ".prettierrc.json"
                                                ".prettierrc.yml"
                                                ".prettierrc.yaml"
                                                ".prettierrc.json5"
                                                ".prettierrc.js" "prettier.config.js"
                                                ".prettierrc.mjs" "prettier.config.mjs"
                                                ".prettierrc.cjs" "prettier.config.cjs"
                                                ".prettierrc.toml")
                                           if (locate-dominating-file default-directory file)
                                           return t)
                                  (when-let ((pkg (locate-dominating-file default-directory "package.json")))
                                    (require 'json)
                                    (let ((json-key-type 'alist))
                                      (assq 'prettier
                                            (json-read-file (expand-file-name "package.json" pkg))))))
                        (apheleia-formatters-indent "--use-tabs" "--tab-width"))))))))

(provide 'psyc-format)
;;; psyc-format.el ends here
