;;; psyclyx-lib.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(defun psyclyx-delete-backward-word (arg)
  "Like `backward-kill-word', but doesn't affect the kill-ring."
  (interactive "p")
  (let ((kill-ring nil) (kill-ring-yank-pointer nil))
    (ignore-errors (backward-kill-word arg))))

(defmacro psyclyx-cmd (&rest body)
  "Returns (lambda () (interactive) ,@body)
  A factory for quickly producing interaction commands, particularly for keybinds
  or aliases."
  (declare (doc-string 1))
  `(lambda (&rest _) (interactive) ,@body))

(defun psyclyx-add-hooks (symbols fn)
  (mapc (lambda (sym) (add-hook sym fn)) symbols))

(defun psyclyx-dired-buffer-p (buf)
  "Returns non-nil if BUF is a dired buffer."
  (provided-mode-derived-p (buffer-local-value 'major-mode buf)
                           'dired-mode))

(defun psyclyx-special-buffer-p (buf)
  "Returns non-nil if BUF's name starts and ends with an *."
  (char-equal ?* (aref (buffer-name buf) 0)))

(defun psyclyx-temp-buffer-p (buf)
  "Returns non-nil if BUF is temporary."
  (char-equal ?\s (aref (buffer-name buf) 0)))

(provide 'psyclyx-lib)
