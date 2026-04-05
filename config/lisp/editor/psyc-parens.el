;;; psyc-parens.el --- Structural editing -*- lexical-binding: t; -*-
;;; Code:

(require 'psyc-lib)

;;;; Electric pair (auto-pairing for non-lisp modes)

(use-package elec-pair
  :ensure nil
  :hook (emacs-startup . electric-pair-mode))

;;;; Expand-region (incremental selection expansion)

(use-package expreg
  :defer t
  :config
  (unless psyc-vanilla-mode
    (general-def
      :states 'visual
      "v" #'expreg-expand
      "V" #'expreg-contract)))

;;;; Multiple cursors

(use-package multiple-cursors
  :defer t
  :init
  (gsetq mc/always-run-for-all t))

;;;; Combobulate (tree-sitter structural editing)

(use-package combobulate
  :hook ((python-ts-mode . combobulate-mode)
         (js-ts-mode . combobulate-mode)
         (typescript-ts-mode . combobulate-mode)
         (tsx-ts-mode . combobulate-mode)
         (css-ts-mode . combobulate-mode)
         (bash-ts-mode . combobulate-mode)))

;;;; Lisp modes

(defvar psyc-lisp-mode-hooks
  '(emacs-lisp-mode-hook
    clojure-mode-hook
    clojurescript-mode-hook
    clojurec-mode-hook
    cider-repl-mode-hook
    janet-mode-hook
    lisp-mode-hook
    scheme-mode-hook
    ielm-mode-hook
    lisp-interaction-mode-hook)
  "Mode hooks where structural editing should be enabled.")

(if psyc-vanilla-mode
    ;; Modal mode: use built-in structural editing via psyc-modal match mode.
    ;; Disable electric-pair in lisp modes (parens handled by our own insert logic).
    (progn
      (defun psyc-modal--lisp-insert-pair ()
        "Auto-close parens/brackets in lisp modes during insert state."
        (electric-pair-local-mode -1)
        ;; Use Emacs built-in skeleton pairs for balanced insertion
        (setq-local skeleton-pair t)
        (local-set-key "(" #'skeleton-pair-insert-maybe)
        (local-set-key "[" #'skeleton-pair-insert-maybe)
        (local-set-key "{" #'skeleton-pair-insert-maybe)
        (local-set-key "\"" #'skeleton-pair-insert-maybe))
      (psyc-add-hooks psyc-lisp-mode-hooks #'psyc-modal--lisp-insert-pair)

      ;; Default lisp local-leader (eval commands via emacs built-ins)
      (with-eval-after-load 'psyc-modal
        (psyc-modal-localleader emacs-lisp-mode-hook "Emacs Lisp"
          "ee" #'eval-last-sexp
          "eb" #'eval-buffer
          "ed" #'eval-defun
          "er" #'eval-region)

        (psyc-modal-localleader lisp-interaction-mode-hook "Lisp Interaction"
          "ee" #'eval-last-sexp
          "eb" #'eval-buffer
          "ed" #'eval-defun
          "er" #'eval-region)))

  ;; Evil mode: smartparens + evil-cleverparens
  (use-package smartparens
    :commands (smartparens-strict-mode)
    :init
    (psyc-add-hooks psyc-lisp-mode-hooks #'smartparens-strict-mode)
    :config
    (require 'smartparens-config)
    (general-def
      :keymaps 'smartparens-strict-mode-map
      :states 'insert
      [remap delete-backward-char] #'sp-backward-delete-char
      [remap backward-delete-char-untabify] #'sp-backward-delete-char
      [remap delete-forward-char] #'sp-delete-char)
    (add-hook 'smartparens-enabled-hook
              (lambda () (electric-pair-local-mode -1))))

  (use-package evil-cleverparens
    :commands (evil-cleverparens-mode)
    :init
    (psyc-add-hooks psyc-lisp-mode-hooks #'evil-cleverparens-mode)
    (gsetq evil-cleverparens-swap-move-by-word-and-symbol t)))

;;;; Polymode (embedded language regions via `# lang: <mode>' comments)

(use-package polymode
  :defer t
  :config
  (define-hostmode poly-nix-hostmode
    :mode 'nix-ts-mode)

  (define-auto-innermode poly-nix-lang-comment-innermode
    :head-matcher "^[[:blank:]]*#[[:blank:]]*lang:[[:blank:]]*\\([^ \t\n]+\\)[[:blank:]]*\n[[:blank:]]*''"
    :tail-matcher "^[[:blank:]]*''"
    :mode-matcher (cons "lang:[[:blank:]]*\\([^ \t\n]+\\)" 1)
    :head-mode 'host
    :tail-mode 'host)

  (define-polymode poly-nix-mode
    :hostmode 'poly-nix-hostmode
    :innermodes '(poly-nix-lang-comment-innermode)))

(with-eval-after-load 'nix-ts-mode
  (require 'polymode)
  (add-hook 'nix-ts-mode-hook #'poly-nix-mode))

(provide 'psyc-parens)
;;; psyc-parens.el ends here
