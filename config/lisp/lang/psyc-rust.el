;;; psyc-rust.el --- Rust language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package rust-ts-mode
  :ensure nil
  :mode "\\.rs\\'"
  :hook (rust-ts-mode . eglot-ensure)
  :init
  (defun psyc-rust--eglot-config ()
    (setq-local eglot-workspace-configuration
                '(:rust-analyzer (:check (:command "clippy")
                                  :cargo (:allFeatures t)))))
  (add-hook 'rust-ts-mode-hook #'psyc-rust--eglot-config))

(provide 'psyc-rust)
;;; psyc-rust.el ends here
