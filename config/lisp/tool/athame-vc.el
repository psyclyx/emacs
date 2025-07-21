;;; athame-vc.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (magit-bury-buffer-function #'magit-restore-window-configuration)
  (magit-save-repository-buffers 'dontask)
  (magit-no-confirm '(stage-all-changes unstage-all-changes)))

(use-package git-gutter-fringe
  :config
  (define-fringe-bitmap 'git-gutter-fr:added [224] nil nil '(center repeated))
  (define-fringe-bitmap 'git-gutter-fr:modified [224] nil nil '(center repeated))
  (define-fringe-bitmap 'git-gutter-fr:deleted [224] nil nil '(center repeated))
  (global-git-gutter-mode))

;;; Provide
(provide 'athame-vc)
;;; athame-vc.el ends here
