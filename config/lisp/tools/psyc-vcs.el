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

(provide 'psyc-vcs)
;;; psyc-vcs.el ends here
