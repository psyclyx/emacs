;;; athame-format.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(defcustom athame-format-on-save-disabled-modes
  '(org-msg-edit-mode) "Don't format on these modes"
  :type '(list symbol))

(use-package apheleia
  :config
  (apheleia-global-mode)

  (add-hook 'apheleia-inhibit-functions
            (defun athame-format-maybe-inhibit-h ()
              (or (eq major-mode 'fundamental-mode)
                  (string-blank-p (buffer-name))
                  (eq athame-format-on-save-disabled-modes t)
                  (not (null (memq major-mode athame-format-on-save-disabled-modes))))))

  ;; HACK: Apheleia suppresses notifications that the current buffer has
  ;;   changed, so plugins that listen for them need to be manually informed:
  (add-hook 'apheleia-post-format-hook
            (defun athame-format--update-web-mode-h ()
              (when (eq major-mode 'web-mode)
                (setq web-mode-fontification-off nil)
                (when (and web-mode-scan-beg web-mode-scan-end global-font-lock-mode)
                  (save-excursion
                    (font-lock-fontify-region web-mode-scan-beg web-mode-scan-end))))))
  (add-hook 'apheleia-post-format-hook #'git-gutter)
  (add-to-list 'apheleia-mode-alist '(sh-mode . shfmt))

  (add-to-list 'apheleia-formatters '(lsp . eglot-format-buffer))

  (setf (alist-get 'nix-mode apheleia-formatters) '("nixfmt" "-s"))

  ;; Use clang-format for cuda and protobuf files.
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

  ;; Apheleia's default config for prettier passes an explicit --tab-width N to
  ;; all prettier formatters, respecting your indent settings in Emacs, but
  ;; overriding any indent settings in your prettier config files. This changes
  ;; it to omit indent switches if any configuration for prettier is present in
  ;; the current project.
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


;;; Provide
(provide 'athame-format)
;;; athame-format.el ends here
