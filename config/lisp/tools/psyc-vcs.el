;;; psyc-vcs.el --- Version control -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(use-package magit
  :defer t
  :config
  (gsetq
   magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1
   magit-bury-buffer-function #'magit-restore-window-configuration
   magit-save-repository-buffers 'dontask
   magit-no-confirm '(stage-all-changes unstage-all-changes)))

;;;; Diff-hl (git gutter)

(use-package diff-hl
  :ghook ('emacs-startup-hook #'global-diff-hl-mode)
  :hook ((dired-mode . diff-hl-dired-mode)
         (magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  (diff-hl-flydiff-mode 1))

(provide 'psyc-vcs)
;;; psyc-vcs.el ends here
