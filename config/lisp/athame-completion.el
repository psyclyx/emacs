;;; athame-completion.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(defun athame-completion--crm-indicator-a (args)
  (cons (format "[CRM%s] %s"
                (string-replace "[ \t]*" "" crm-separator)
                (car args))
        (cdr args)))

(when (< emacs-major-version 31)
  (advice-add #'completing-read-multiple :filter-args
              #'athame-completion--crm-indicator-a))

;;;; Orderless
(defun athame-vertico--orderless-dispatch (pattern _index _total)
  (let ((len (length pattern))
        (alist orderless-affix-dispatch-alist))
    (when (> len 0)
      (cond
       ;; Ignore single dispatcher character
       ((and (= len 1) (alist-get (aref pattern 0) alist)) #'ignore)
       ;; Prefix
       ((when-let ((style (alist-get (aref pattern 0) alist))
                   ((not (char-equal (aref pattern (max (1- len) 1)) ?\\))))
          (cons style (substring pattern 1))))
       ;; Suffix
       ((when-let ((style (alist-get (aref pattern (1- len)) alist))
                   ((not (char-equal (aref pattern (max 0 (- len 2))) ?\\))))
          (cons style (substring pattern 0 -1))))))))


(defun athame-vertico--orderless-disambiguation-dispatch (pattern _index _total)
  (when (char-equal (aref pattern (1- (length pattern))) ?$)
    `(orderless-regexp . ,(concat (substring pattern 0 -1) "[\x200000-\x300000]*$"))))


(defun athame-vertico--company-capf--candidates-a (fn &rest args)
  (let ((orderless-match-faces [completions-common-part])
        (completion-styles '(basic partial-completion orderless)))
    (apply fn args)))


(use-package orderless
  :defer t
  :init
  (gsetq orderless-affix-dispatch-alist
         '((?! . orderless-without-literal)
           (?& . orderless-annotation)
           (?% . char-fold-to-regexp)
           (?` . orderless-initialism)
           (?= . orderless-literal)
           (?^ . orderless-literal-prefix)
           (?~ . orderless-flex))
         orderless-style-dispatchers
         '(athame-vertico--orderless-dispatch
           athame-vertico--orderless-disambiguation-dispatch))
  (gsetq completion-styles '(orderless basic)
         completion-category-defaults nil
         completion-category-overrides '((file (styles orderless partial-completion))))
  :config
  (gsetq orderless-component-separator #'orderless-escapable-split-on-space)
  (advice-add 'company-capf--candidates :around #'athame-vertico--company-capf--candidates-a)
  (set-face-attribute 'completions-first-difference nil :inherit nil))

;;;; Consult
(use-package consult
  :init
  (gsetq
   consult-narrow-key "<"
   consult-line-numbers-width t
   consult-async-min-input 2
   consult-async-refresh-delay  0.15
   consult-async-input-throttle 0.2
   consult-async-input-debounce 0.1
   register-preview-delay 0.5)
  (advice-add #'register-preview :override #'consult-register-window)
  :config
  :general
  ([remap bookmark-jump]                 #'consult-bookmark
   [remap evil-show-marks]               #'consult-mark
   [remap evil-show-registers]           #'consult-register
   [remap goto-line]                     #'consult-goto-line
   [remap imenu]                         #'consult-imenu
   [remap Info-search]                   #'consult-info
   [remap list-dir]                      #'consult-dir
   [remap locate]                        #'consult-locate
   [remap load-theme]                    #'consult-theme
   [remap recentf-open-files]            #'consult-recent-file
   [remap switch-to-buffer]              #'consult-buffer
   [remap switch-to-buffer-other-window] #'consult-buffer-other-window
   [remap switch-to-buffer-other-frame]  #'consult-buffer-other-frame
   [remap yank-pop]                      #'consult-yank-pop)

  :config
  (gsetq xref-show-xrefs-function #'consult-xref
	 xref-show-definitions-function #'consult-xref)
  (consult-customize
   consult-theme
   :preview-key '(:debounce 0.1 any)
   consult-ripgrep consult-git-grep consult-grep consult-man
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   :preview-key '(:debounce 0.3 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file
   consult--source-recent-file consult--source-project-recent-file consult--source-bookmark
   :preview-key "C-SPC")

  (general-with-eval-after-load 'evil
    (gsetq evil-jumps-cross-buffers nil)
    (evil-set-command-property 'consult-line :jump t))

  (general-with-eval-after-load 'vertico
    (general-def
      :keymaps 'vertico-map
      "C-x C-d" #'consult-dir
      "C-x C-j" #'consult-dir-jump-file)))

;;;; Marginalia
(use-package marginalia
  :after vertico
  :ghook 'vertico-mode-hook
  :init
  (gsetq marginalia-max-relative-age 0)
  :config
  (add-to-list 'marginalia-prompt-categories '("\\<face\\>" . face))
  (add-to-list 'marginalia-prompt-categories '("\\<var\\>" . variable)))

(use-package nerd-icons-completion
  :after marginalia
  :ghook ('marginalia-mode-hook #'nerd-icons-completion-marginalia-setup)
  :config
  (general-after-gui
    (nerd-icons-completion-marginalia-setup)))

;;; Provide
(provide 'athame-completion)
;;; athame-completion.el ends here
