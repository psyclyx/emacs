;;; athame-cape -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(defun athame-cape--add-elisp-block-capf-h ()
  (add-hook 'completion-at-point-functions #'cape-elisp-block 0 t))

(defvar athame-cape--buffer-scan-limit (* 1 1024 1024))

(defun athame-cape--dabbrev-friendly-buffer (other-buffer)
  (< (buffer-size other-buffer) athame-cape--buffer-scan-limit))

(use-package cape
  :init
  (gsetq
   cape-dabbrev-check-other-buffers t
   dabbrev-friend-buffer-function #'athame-cape--dabbrev-friendly-buffer
   dabbrev-ignored-buffer-regexps
   '("\\` "
     "\\(?:\\(?:[EG]?\\|GR\\)TAGS\\|e?tags\\|GPATH\\)\\(<[0-9]+>\\)?")
   dabbrev-upcase-means-case-search t)
  :ghook
  ((list 'org-mode-hook 'markdown-mode-hook) #'athame-cape--add-elisp-block-capf-h)
  :config
  (general-after-init
    (add-to-list 'completion-at-point-functions #'cape-dabbrev)
    (add-to-list 'completion-at-point-functions #'cape-keyword)
    (add-to-list 'completion-at-point-functions #'cape-file))
  (general-advice-add (list #'comint-completion-at-point #'eglot-completion-at-point #'pcomplete-completions-at-point)
		      :around #'cape-wrap-nonexclusive))

(provide 'athame-cape)
;;; athame-cape.el ends here
