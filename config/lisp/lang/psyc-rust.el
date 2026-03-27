;;; psyc-rust.el --- Rust language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package rust-ts-mode
  :ensure nil
  :mode "\\.rs\\'"
  :hook (rust-ts-mode . eglot-ensure)
  :init
  (with-eval-after-load 'eglot
    (setq-default eglot-workspace-configuration
                  '(:rust-analyzer (:check (:command "clippy")
                                   :cargo (:allFeatures t))))))

(provide 'psyc-rust)
;;; psyc-rust.el ends here
