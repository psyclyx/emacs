;;; athame-compile.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:


(defun athame-compile (arg)
  "Runs `compile' from the root of the current project.

If a compilation window is already open, recompile that instead.

If ARG (universal argument), runs `compile' from the current directory."
  (interactive "P")
  (if (and (bound-and-true-p compilation-in-progress)
           (buffer-live-p compilation-last-buffer))
      (recompile)
    (call-interactively
     (if arg
         #'project-compile
       #'compile))))

;;; Provide
(provide 'athame-compile)
;;; athame-compile.el ends here
