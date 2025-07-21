;;; athame-file.el -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code

;;;; Follow symlinks
(setq find-file-visit-truename t
      vc-follow-symlinks t
      find-file-suppress-same-file-warnings t)

;;;; Declutter
(setq create-lockfiles nil
      make-backup-files nil)

;;;; Recent files
(use-package recentf
  :custom
  (recentf-save-file (file-name-concat athame-state-dir "recentf"))
  (recentf-max-saved-items 512)
  :config
  (recentf-mode 1)
  (add-to-list 'recentf-exclude
               (concat "^" (regexp-quote (or (getenv "XDG_RUNTIME_DIR")
                                             "/run"))))
  (add-to-list 'recentf-exclude (concat "^/nix/store" ))
  (add-to-list 'recentf-filename-handlers #'substring-no-properties))


;;;; Hooks
;;;;; Create missing directories
(defun athame-file--create-missing-directories-h ()
  "Automatically create missing directories when creating new files."
  (unless (file-remote-p buffer-file-name)
    (let ((parent-directory (file-name-directory buffer-file-name)))
      (and (not (file-directory-p parent-directory))
           (y-or-n-p (format "Directory `%s' does not exist! Create it?"
                             parent-directory))
           (progn (make-directory parent-directory 'parents)
                  t)))))

(add-hook 'find-file-not-found-functions
          #'athame-file--create-missing-directories-h)

;;;;; Guess major mode on save
(defun athame--file-guess-mode-h ()
  "Guess major mode when saving a file in `fundamental-mode'.

Likely, something has changed since the buffer was opened. e.g. A shebang line
or file path may exist now."
  (when (eq major-mode 'fundamental-mode)
    (let ((buffer (or (buffer-base-buffer) (current-buffer))))
      (and (buffer-file-name buffer)
           (eq buffer (window-buffer (selected-window)))
           (set-auto-mode)
           (not (eq major-mode 'fundamental-mode))))))
(add-hook 'after-save-hook #'athame--file-guess-mode-h)

;;; Provide
(provide 'athame-file)
;;; athame-file.el ends here
