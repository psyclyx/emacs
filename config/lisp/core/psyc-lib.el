;;; psyc-lib.el --- Core library and utilities -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'cl-lib)
(require 'dash)

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

;;;; General (keybinding framework)

(use-package general
  :ensure t
  :demand t
  :config
  (general-override-mode +1)
  (defalias 'gsetq #'general-setq))

(provide 'psyc-lib)
;;; psyc-lib.el ends here
