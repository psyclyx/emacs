;;; psyc-windows.el --- Window management -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(gsetq display-buffer-alist
       '(("\\*eldoc\\*"
          (display-buffer-reuse-mode-window
           display-buffer-in-side-window)
          (side . right)
          (slot . 0)
          (width . 0.3))
         ("\\*[hH]elp\\(ful.*\\)?\\*"
          (display-buffer-reuse-mode-window
           display-buffer-in-side-window)
          (side . right)
          (slot . -1)
          (width . 0.3))
         ("\\*info\\*"
          (display-buffer-reuse-mode-window
           display-buffer-in-side-window)
          (side . right)
          (slot . 1)
          (width . 0.3))
	 ("^\\*image-dired"
	  (display-buffer-reuse-mode-window
	   display-buffer-at-bottom)
	  (size . 0.8)
	  (select . t))))

(provide 'psyc-windows)
;;; psyc-windows.el ends here
