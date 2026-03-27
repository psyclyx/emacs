;;; psyc-dired.el --- Dired and file manager configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

;;;; Dired

(use-package dired
  :commands dired-jump
  :init
  (gsetq dired-dwim-target t
	 dired-auto-revert-buffer t
	 dired-recursive-copies 'always
	 dired-recursive-deletes 'top
	 dired-create-destination-dirs 'ask
	 image-dired-dir (expand-file-name "image-dired/" psyc-cache-dir)
	 image-dired-db-file (expand-file-name "image-dired/db.el" psyc-cache-dir)
	 image-dired-gallery-dir (expand-file-name "image-dired/gallery" psyc-cache-dir)
	 image-dired-temp-image-file (expand-file-name "image-dired/temp-image" psyc-cache-dir)
	 image-dired-temp-rotate-image-file (expand-file-name "image-dired/temp-rotate-image" psyc-cache-dir)
	 image-dired-thumb-size 150)
  :config
  (general-after 'evil
    (evil-set-initial-state 'image-dired-display-image-mode 'emacs))
  (put 'dired-find-alternate-file 'disabled nil))

;;;; Dirvish

(use-package dirvish
  :init
  (gsetq dirvish-cache-dir (expand-file-name "dirvish/" psyc-cache-dir)
	 dirvish-attributes '(file-size nerd-icons subtree-state)
	 dirvish-hide-details '(dirvish dirvish-side)
	 dirvish-hide-cursor '(dirvish dirvish-side)
	 dirvish-mode-line-format '(:left
				    (sort file-time symlink)
				    :right
				    (omit yank index))
	 dirvish-subtree-always-show-state t)
  (dirvish-override-dired-mode)
  :general (:keymaps 'dired-mode-map "C-c C-r" #'dirvish-rsync)
  :general-config
  (:keymaps
   'dirvish-mode-map
   :states 'normal
   "?" #'dirvish-dispatch
   "q" #'dirvish-quit
   "b" #'dirvish-quick-access
   "f" #'dirvish-file-info-menu
   "p" #'dirvish-yank
   "S" #'dirvish-quicksort
   "F" #'dirvish-layout-toggle
   "z" #'dirvish-history-jump
   "gh" #'dirvish-subtree-up
   "gl" #'dirvish-subtree-toggle
   "h" #'dired-up-directory
   "l" #'dired-find-file)
  (:keymaps
   'dirvish-mode-map
   :states 'motion
   [left]  #'dired-up-directory
   [right] #'dired-find-file
   "[h" #'dirvish-history-go-backward
   "]h" #'dirvish-history-go-forward
   "[e" #'dirvish-emerge-next-group
   "]e" #'dirvish-emerge-previous-group)
  (:keymaps
   'dirvish-mode-map
   :states 'normal
   "TAB" #'dirvish-subtree-toggle
   "M-b" #'dirvish-history-go-backward
   "M-f" #'dirvish-history-go-forward
   "M-n" #'dirvish-narrow
   "M-m" #'dirvish-mark-menu
   "M-s" #'dirvish-setup-menu
   "M-e" #'dirvish-emerge-menu
   "y" (cons "yank" nil)
   "y l" #'dirvish-copy-file-true-path
   "y n" #'dirvish-copy-file-name
   "y p" #'dirvish-copy-file-path
   "y r" #'dirvish-copy-remote-path
   "y y" #'dirvish-do-copy
   "s" (cons "symlinks" nil)
   "s" #'dirvish-symlink
   "S" #'dirvish-relative-symlink
   "h" #'dirvish-hardlink))

;;;; Diredfl

(use-package diredfl
  :ghook 'dired-mode-hook 'dirvish-directory-view-mode-hook)

;;;; Dired-x

(use-package dired-x
  :ghook ('dired-mode-hook #'dired-omit-mode)
  :config
  (gsetq dired-omit-files
	 (concat dired-omit-files
		 "\\|^\\.DS_Store\\'"
		 "\\|^flycheck_.*"
		 "\\|^\\.project\\(?:ile\\)?\\'"
		 "\\|^\\.\\(?:svn\\|git\\)\\'"
		 "\\|^\\.ccls-cache\\'"
		 "\\|\\(?:\\.js\\)?\\.meta\\'"
		 "\\|\\.\\(?:elc\\|o\\|pyo\\|swp\\|class\\)\\'")
	 dired-clean-confirm-killing-deleted-buffers nil)
  (when-let (cmd (cond ((featurep :system 'macos) "open")
                       ((featurep :system 'linux) "xdg-open")
                       ((featurep :system 'windows) "start")))
    (gsetq dired-guess-shell-alist-user
           `(("\\.\\(?:docx\\|pdf\\|djvu\\|eps\\)\\'" ,cmd)
             ("\\.\\(?:jpe?g\\|png\\|gif\\|xpm\\)\\'" ,cmd)
             ("\\.\\(?:xcf\\)\\'" ,cmd)
             ("\\.tex\\'" ,cmd)
             ("\\.\\(?:mp4\\|mkv\\|avi\\|flv\\|rm\\|rmvb\\|ogv\\)\\(?:\\.part\\)?\\'" ,cmd)
             ("\\.\\(?:mp3\\|flac\\)\\'" ,cmd)
             ("\\.html?\\'" ,cmd)))))

(provide 'psyc-dired)
;;; psyc-dired.el ends here
