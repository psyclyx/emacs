;;; athame-vc.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(use-package magit
  :defer t
  :custom
  (gsetq
   magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1
   magit-bury-buffer-function #'magit-restore-window-configuration
   magit-save-repository-buffers 'dontask
   magit-no-confirm '(stage-all-changes unstage-all-changes)))

;;; Provide
(provide 'athame-vc)
;;; athame-vc.el ends here
