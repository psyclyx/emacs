;;; psyclyx-completion.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(use-package corfu
    :ensure t
    :defer 0.1
    :custom
    (corfu-auto t)
    (corfu-auto-delay 0.24)
    (corfu-auto-prefix 2)
    (global-corfu-modes '((not erc-mode
                               help-mode
                               vterm-mode)
                          t))
    (corfu-cycle t)
    (corfu-preselect 'prompt)
    (corfu-count 16)
    (corfu-max-width 120)
    (corfu-on-exact-match nil)
    (corfu-quit-at-boundary 'separator)
    (corfu-quit-no-match corfu-quit-at-boundary)
    (tab-always-indent 'complete)
    :config
    (global-corfu-mode)
    (add-to-list 'completion-category-overrides `(lsp-capf (styles ,@completion-styles)))
    (add-hook 'evil-insert-state-exit-hook #'corfu-quit)

    (defun my/corfu--smart-sep-toggle-escape ()
      "Insert `corfu-separator' or toggle escape if it's already there."
      (interactive)
      (cond ((and (char-equal (char-before) corfu-separator)
                  (char-equal (char-before (1- (point))) ?\\))
             (save-excursion (delete-char -2)))
            ((char-equal (char-before) corfu-separator)
             (save-excursion (backward-char 1)
                             (insert-char ?\\)))
            (t (call-interactively #'corfu-insert-separator))))

    (add-to-list 'corfu-continue-commands #'my/corfu--smart-sep-toggle-escape)

    (defun my/corfu--other-completion-active-p ()
      (or (bound-and-true-p vertico--input)
          (where-is-internal 'minibuffer-complete (list (current-local-map)))))

    (defun my/corfu--enable-in-minibuffer-p ()
      (and (where-is-internal #'completion-at-point
                              (list (current-local-map)))
           (not (my/corfu--other-completion-active-p))))

    (setq global-corfu-minibuffer #'my/corfu--enable-in-minibuffer-p))


    (defvar my/corfu-buffer-scanning-size-limit (* 1 1024 1024))

(use-package cape
  :ensure t
  :after (dabbrev)
  :custom
  (cape-dabbrev-check-other-buffers t)
  :init
  (defun my/corfu-add-cape-file-h ()
    (add-hook 'completion-at-point-functions #'cape-file -10 t))
  (add-hook 'prog-mode-hook #'my/corfu-add-cape-file-h)

  (defun my/corfu-add-cape-elisp-block-h ()
    (add-hook 'completion-at-point-functions #'cape-elisp-block 0 t))
  (my/add-hooks '(org-mode-hook markdown-mode-hook) #'my/corfu-add-cape-elisp-block-h)

  (defun my/corfu-add-cape-dabbrev-h ()
    (add-hook 'completion-at-point-functions #'cape-dabbrev 20 t))
  (my/add-hooks '(prog-mode-hook
                  text-mode-hook
                  conf-mode-hook
                  comint-mode-hook
                  minibuffer-setup-hook
                  eshell-mode-hook)
                #'my/corfu-add-cape-dabbrev-h)

  (defun my/corfu-dabbrev-friend-buffer-p (other-buffer)
    (< (buffer-size other-buffer) +corfu-buffer-scanning-size-limit))

  (setq dabbrev-friend-buffer-function #'my/corfu-dabbrev-friend-buffer-p
        dabbrev-ignored-buffer-regexps
        '("\\` "
          "\\(?:\\(?:[EG]?\\|GR\\)TAGS\\|e?tags\\|GPATH\\)\\(<[0-9]+>\\)?")
        dabbrev-upcase-means-case-search t)

  (advice-add #'comint-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'eglot-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'pcomplete-completions-at-point :around #'cape-wrap-nonexclusive))


(use-package vertico
  :ensure t
  :custom
  (vertico-cycle t)
  (vertico-count 20)
  (vertico-resize t)

  :config
  (vertico-mode)
  (general-def
    :keymaps 'vertico-map
    "M-j" 'next-line
    "M-k" 'previous-line
    "M-h" 'backward-paragraph
    "M-l" 'forward-paragraph)

  ;; Prompt indicator for `completing-read-multiple'.
  (when (< emacs-major-version 31)
    (advice-add #'completing-read-multiple :filter-args
                (lambda (args)
                  (cons (format "[CRM%s] %s"
                                (string-replace "[ \t]*" "" crm-separator)
                                (car args))
                        (cdr args))))))

(require 'vertico-buffer)
(require 'vertico-grid)
(require 'vertico-directory)
(require 'vertico-reverse)
(require 'vertico-repeat)
(require 'vertico-multiform)

(add-hook 'rfn-esm-update-handlers #'vertico-directory-tidy)

(general-def
  :keymaps '(vertico-map vertico-mulltiform-map)
  "RET" 'vertico-directory-enter
  "DEL" 'vertico-directory-delete-char
  "M-DEL" 'vertico-directory-delete-word)

(setq vertico-buffer-display-action '(display-buffer-use-least-recent-window)
      vertico-multiform-categories '((embark-keybinding grid)))

(vertico-multiform-mode)

(add-hook 'minibuffer-setup-hook #'vertico-repeat-save)

(general-def
  :states '(normal insert visual motion)
  "C-M-;" 'vertico-repeat)

(advice-add #'ffap-menu-ask :around
            (lambda (&rest args)
              (cl-letf (((symbol-function #'minibuffer-completion-help)
                         #'ignore))
                (apply args))))

(defun my/vertico--orderless-dispatch (pattern _index _total)
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

(use-package consult
  :ensure t
  :after (evil vertico)

  :preface
  (general-def
    [remap bookmark-jump]                 #'consult-bookmark
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
  :init
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)

  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  :config
  (consult-customize
   consult-theme :preview-key '(:debounce 0.1 any)
   consult-ripgrep consult-git-grep consult-grep consult-man
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   :preview-key '(:debounce 0.3 any))

  (setq consult-narrow-key "<"
        consult-line-numbers-width t
        consult-async-min-input 2
        consult-async-refresh-delay  0.15
        consult-async-input-throttle 0.2
        consult-async-input-debounce 0.1)

  (setq evil-jumps-cross-buffers nil)
  (evil-set-command-property 'consult-line :jump t)
  (general-def
    :keymaps 'vertico-map
    "C-x C-d" #'consult-dir
    "C-x C-j" #'consult-dir-jump-file)

  (consult-customize
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file
   consult--source-recent-file consult--source-project-recent-file consult--source-bookmark
   :preview-key "C-SPC"))


(use-package marginalia
  :ensure t
  :init
  (marginalia-mode)
  :custom
  (marginalia-max-relative-age 0)
  :config
  (add-to-list 'marginalia-prompt-categories '("\\<face\\>" . face))
  (add-to-list 'marginalia-prompt-categories '("\\<var\\>" . variable)))

(provide 'psyclyx-completion.el)
