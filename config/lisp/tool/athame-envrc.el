;;; athame-envrc.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(use-package envrc
  :ghook ('emacs-startup-hook #'envrc-global-mode))

;;; Provide
(provide 'athame-envrc)
;;; athame-envrc.el ends here
