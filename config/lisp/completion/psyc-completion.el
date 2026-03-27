;;; psyc-completion.el --- Completion framework -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

;;;; Orderless

(defun psyc-orderless--dispatch (pattern _index _total)
  (let ((len (length pattern))
        (alist orderless-affix-dispatch-alist))
    (when (> len 0)
      (cond
       ((and (= len 1) (alist-get (aref pattern 0) alist)) #'ignore)
       ((when-let ((style (alist-get (aref pattern 0) alist))
                   ((not (char-equal (aref pattern (max (1- len) 1)) ?\\))))
          (cons style (substring pattern 1))))
       ((when-let ((style (alist-get (aref pattern (1- len)) alist))
                   ((not (char-equal (aref pattern (max 0 (- len 2))) ?\\))))
          (cons style (substring pattern 0 -1))))))))

(defun psyc-orderless--disambiguation-dispatch (pattern _index _total)
  (when (char-equal (aref pattern (1- (length pattern))) ?$)
    `(orderless-regexp . ,(concat (substring pattern 0 -1)
                                  "[\x200000-\x300000]*$"))))

(use-package orderless
  :defer t
  :init
  (gsetq completion-styles '(orderless basic)
         completion-category-defaults nil
         completion-category-overrides
         '((file (styles orderless partial-completion))
           (eglot (styles orderless))
           (eglot-capf (styles orderless)))
         orderless-affix-dispatch-alist
         '((?! . orderless-without-literal)
           (?& . orderless-annotation)
           (?% . char-fold-to-regexp)
           (?` . orderless-initialism)
           (?= . orderless-literal)
           (?^ . orderless-literal-prefix)
           (?~ . orderless-flex))
         orderless-style-dispatchers
         '(psyc-orderless--dispatch
           psyc-orderless--disambiguation-dispatch))

  :config
  (gsetq orderless-component-separator #'orderless-escapable-split-on-space)
  (set-face-attribute 'completions-first-difference nil :inherit nil))

;;;; Corfu

(defun psyc-corfu-move-to-minibuffer ()
  (interactive)
  (pcase completion-in-region--data
    (`(,beg ,end ,table ,pred ,extras)
     (let ((completion-extra-properties extras)
           completion-cycle-threshold completion-cycling)
       (consult-completion-in-region beg end table pred)))))

(defun psyc-corfu-smart-sep-toggle-escape ()
  "Insert `corfu-separator' or toggle escape if already present."
  (interactive)
  (cond ((and (char-equal (char-before) corfu-separator)
              (char-equal (char-before (1- (point))) ?\\))
         (save-excursion (delete-char -2)))
        ((char-equal (char-before) corfu-separator)
         (save-excursion (backward-char 1)
                         (insert-char ?\\)))
        (t (call-interactively #'corfu-insert-separator))))

(defun psyc-corfu-dabbrev-or-next (&optional arg)
  "Dabbrev-complete or move to next candidate if popup is open."
  (interactive "p")
  (if corfu--candidates
      (corfu-next arg)
    (require 'cape)
    (let ((cape-dabbrev-check-other-buffers
           (bound-and-true-p evil-complete-all-buffers)))
      (cape-dabbrev t)
      (when (> corfu--total 0)
        (corfu--goto (or arg 0))))))

(defun psyc-corfu-dabbrev-or-prev (&optional arg)
  "Dabbrev-complete or move to previous candidate if popup is open."
  (interactive "p")
  (if corfu--candidates
      (corfu-previous arg)
    (require 'cape)
    (let ((cape-dabbrev-check-other-buffers
           (bound-and-true-p evil-complete-all-buffers)))
      (cape-dabbrev t)
      (when (> corfu--total 0)
        (corfu--goto (- corfu--total (or arg 1)))))))

(defun psyc-corfu--enable-in-minibuffer-p ()
  (and (where-is-internal #'completion-at-point (list (current-local-map)))
       (not (bound-and-true-p vertico--input))
       (not (where-is-internal 'minibuffer-complete (list (current-local-map))))))

(use-package corfu
  :ghook ('emacs-startup-hook #'global-corfu-mode)
  :init
  (gsetq corfu-auto t
         corfu-auto-delay 0.24
         corfu-auto-prefix 2
         corfu-auto-trigger '(?. ?> ?:)
         corfu-cycle t
         corfu-preselect 'prompt
         corfu-count 16
         corfu-max-width 120
         corfu-quit-at-boundary 'separator
         corfu-quit-no-match 'separator
         tab-always-indent 'complete
         global-corfu-minibuffer #'psyc-corfu--enable-in-minibuffer-p)

  :config
  (add-to-list 'corfu-continue-commands #'psyc-corfu-smart-sep-toggle-escape)
  (add-hook 'evil-insert-state-exit-hook #'corfu-quit)

  :general-config
  (:keymaps 'corfu-mode-map :states 'insert
            "C-SPC" #'completion-at-point
            "C-n" #'psyc-corfu-dabbrev-or-next
            "C-p" #'psyc-corfu-dabbrev-or-prev)
  (:keymaps 'corfu-mode-map :states 'normal
            "C-SPC" (psyc-cmd (evil-insert-state) (completion-at-point)))
  (:keymaps 'corfu-map :states 'insert
            "C-SPC" #'psyc-corfu-smart-sep-toggle-escape
            "C-S-s" #'psyc-corfu-move-to-minibuffer)
  (:keymaps 'corfu-map
            "TAB" #'corfu-next
            "S-TAB" #'corfu-previous
            [backtab] #'corfu-previous
            "C-j" #'corfu-next
            "C-k" #'corfu-previous))

(use-package corfu-history
  :hook corfu-mode
  :config
  (with-eval-after-load 'savehist
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(use-package corfu-popupinfo
  :hook corfu-mode
  :init
  (gsetq corfu-popupinfo-delay '(0.15 . 0.3))
  :general-config
  (:keymaps 'corfu-popupinfo-map
            "C-h" #'corfu-popupinfo-toggle
            "C-<up>" #'corfu-popupinfo-scroll-down
            "C-<down>" #'corfu-popupinfo-scroll-up))

(use-package nerd-icons-corfu
  :defer t
  :init
  (gsetq corfu-margin-formatters (list #'nerd-icons-corfu-formatter)))

;;;; Cape

(use-package cape
  :defer 0.5
  :ghook
  ('(org-mode-hook markdown-mode-hook)
   #'(lambda () (add-hook 'completion-at-point-functions #'cape-elisp-block 0 t)))

  :init
  (gsetq cape-dabbrev-buffer-function #'cape-same-mode-buffers
         dabbrev-upcase-means-case-search t)

  :config
  (dolist (fn '(cape-dabbrev cape-file))
    (add-hook 'completion-at-point-functions fn))

  (dolist (fn '(eglot-completion-at-point
                comint-completion-at-point
                pcomplete-completions-at-point))
    (advice-add fn :around #'cape-wrap-nonexclusive))

  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster)

  :general-config
  (:keymaps 'override :states 'insert
            "C-c p" '("cape" . cape-prefix-map)))

;;;; Vertico

(use-package vertico
  :ghook 'emacs-startup-hook
  :init
  (gsetq vertico-cycle t
         vertico-count 20
         vertico-resize t)
  :general-config
  (:keymaps 'vertico-map
            "M-j" #'next-line
            "M-k" #'previous-line
            "M-h" #'backward-paragraph
            "M-l" #'forward-paragraph))

(use-package vertico-directory
  :defer t
  :after vertico
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package vertico-buffer
  :defer t
  :after vertico)

(use-package vertico-multiform
  :ghook 'vertico-mode-hook
  :init
  (gsetq vertico-multiform-categories '((embark-keybinding grid)))
  :general
  (:keymaps '(vertico-map vertico-multiform-map)
            "RET" #'vertico-directory-enter
            "DEL" #'vertico-directory-delete-char
            "M-DEL" #'vertico-directory-delete-word))

(use-package vertico-repeat
  :defer t
  :hook (minibuffer-setup . vertico-repeat-save)
  :general-config
  (:states '(normal insert visual motion)
           "C-M-;" #'vertico-repeat))

;;;; Consult

(use-package consult
  :init
  (gsetq consult-narrow-key "<"
         consult-line-numbers-width t
         consult-async-min-input 2
         consult-async-refresh-delay  0.15
         consult-async-input-throttle 0.2
         consult-async-input-debounce 0.1
         register-preview-delay 0.5)
  (advice-add #'register-preview :override #'consult-register-window)

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
   consult-source-bookmark consult-source-file-register
   consult-source-recent-file consult-source-project-recent-file
   :preview-key '(:debounce 0.3 any))

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

;;;; CRM indicator (fixed upstream in Emacs 31)

(when (< emacs-major-version 31)
  (defun psyc-completion--crm-indicator-a (args)
    (cons (format "[CRM%s] %s"
                  (string-replace "[ \t]*" "" crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args
              #'psyc-completion--crm-indicator-a))

(provide 'psyc-completion)
;;; psyc-completion.el ends here
