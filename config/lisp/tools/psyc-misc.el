;;; psyc-misc.el --- Miscellaneous tools -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

;;;; Envrc

(use-package envrc
  :ghook ('emacs-startup-hook #'envrc-global-mode))

;;;; Ispell

(use-package ispell
  :defer t
  :init
  (gsetq ispell-program-name "aspell"))

;;;; Compile

(defun psyc-compile (arg)
  "Runs `project-compile' from the project root.

If a compilation window is already open, recompile that instead.

If ARG (universal argument), runs `compile' from the current directory."
  (interactive "P")
  (if (buffer-live-p compilation-last-buffer)
      (recompile)
    (call-interactively
     (if arg
         #'compile
       #'project-compile))))

(provide 'psyc-misc)
;;; psyc-misc.el ends here
