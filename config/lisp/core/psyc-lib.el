;;; psyc-lib.el --- Core library and utilities -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'cl-lib)

;;;; General (keybinding framework — loaded early for :ghook/:general use-package keywords)

(use-package general
  :demand t
  :config
  (general-override-mode +1))

;;;; No-littering

(defvar psyc-cache-dir "~/.cache/emacs")
(defvar psyc-state-dir "~/.local/state/emacs")

(use-package no-littering
  :demand t
  :init
  (setq no-littering-etc-directory (file-name-concat psyc-state-dir "etc/")
        no-littering-var-directory (file-name-concat psyc-state-dir "var/"))
  :config
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  (when (fboundp 'startup-redirect-eln-cache)
    (startup-redirect-eln-cache
     (convert-standard-filename
      (no-littering-expand-var-file-name "eln-cache/")))))

;;;; Vanilla mode — set to t before init to disable evil and custom keybinds

(defvar psyc-use-evil nil
  "When non-nil, use evil-mode instead of psyc-modal.
Set this in early-init.el or via `emacs --eval \"(setq psyc-use-evil t)\"'.")

;;;; Helpers

(defun psyc-delete-backward-word (arg)
  "Like `backward-kill-word', but doesn't affect the kill-ring."
  (interactive "p")
  (let ((kill-ring nil) (kill-ring-yank-pointer nil))
    (ignore-errors (backward-kill-word arg))))

(defmacro psyc-cmd (&rest body)
  "Returns (lambda () (interactive) ,@body)
  A factory for quickly producing interaction commands, particularly for keybinds
  or aliases."
  (declare (doc-string 1))
  `(lambda (&rest _) (interactive) ,@body))

(defun psyc-add-hooks (symbols fn)
  (mapc (lambda (sym) (add-hook sym fn)) symbols))

(defun psyc-dired-buffer-p (buf)
  "Returns non-nil if BUF is a dired buffer."
  (provided-mode-derived-p (buffer-local-value 'major-mode buf)
                           'dired-mode))

(defun psyc-special-buffer-p (buf)
  "Returns non-nil if BUF's name starts and ends with an *."
  (char-equal ?* (aref (buffer-name buf) 0)))

(defun psyc-temp-buffer-p (buf)
  "Returns non-nil if BUF is temporary."
  (char-equal ?\s (aref (buffer-name buf) 0)))

;;;; gsetq — like `setq' but respects defcustom :set

(defmacro gsetq (&rest settings)
  "Like `setq' but uses the defcustom :set handler when known.
Falls back to `set' when no custom setter exists, avoiding autoloads
for packages that haven't loaded yet."
  `(progn
     ,@(cl-loop for (var val) on settings by #'cddr
                collect `(funcall (or (get ',var 'custom-set) #'set)
                                  ',var ,val))))

(provide 'psyc-lib)
;;; psyc-lib.el ends here
