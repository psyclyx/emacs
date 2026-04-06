;;; psyc-org.el --- Org-mode configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

(defvar psyc-org-dir "~/org/")

(use-package org
  :defer t
  :init
  (gsetq
   org-directory psyc-org-dir
   org-default-notes-file (concat psyc-org-dir "inbox.org")

   ;; TODO workflow: TODO and NEXT are active, WAITING is blocked,
   ;; DONE and CANCELLED are finished.
   org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)")
     (sequence "WAITING(w@)" "|" "CANCELLED(c@)"))

   ;; Log completion time
   org-log-done 'time
   org-log-into-drawer t

   ;; Refile: allow refiling to any heading (up to 3 levels deep)
   ;; in these files. This is where inbox items go to live.
   org-refile-targets '(("todo.org" :maxlevel . 2)
                        ("projects.org" :maxlevel . 2)
                        ("notes.org" :maxlevel . 2))
   org-refile-use-outline-path 'file
   org-outline-path-complete-in-steps nil

   ;; Agenda pulls from these files
   org-agenda-files (list (concat psyc-org-dir "todo.org")
                          (concat psyc-org-dir "projects.org")
                          (concat psyc-org-dir "inbox.org"))

   ;; Capture templates: the key insight is everything lands in inbox
   ;; unless it's a journal entry (which has its own place).
   org-capture-templates
   `(("t" "Task" entry (file ,(concat psyc-org-dir "inbox.org"))
      "* TODO %?\n%U\n" :empty-lines 1)

     ("n" "Note" entry (file ,(concat psyc-org-dir "inbox.org"))
      "* %?\n%U\n" :empty-lines 1)

     ("j" "Journal" entry
      (file+datetree ,(concat psyc-org-dir "notes.org"))
      "* %?\n%U\n" :empty-lines 1))

   ;; Agenda view: show a simple daily/weekly view + all TODOs
   org-agenda-custom-commands
   '(("d" "Dashboard"
      ((agenda "" ((org-agenda-span 'week)))
       (todo "NEXT" ((org-agenda-overriding-header "Up Next")))
       (todo "WAITING" ((org-agenda-overriding-header "Blocked/Waiting")))
       (tags-todo "inbox"
                  ((org-agenda-overriding-header "Inbox (refile me)")
                   (org-agenda-files
                    (list (concat org-directory "inbox.org"))))))))

   ;; Start week on Monday
   org-agenda-start-on-weekday 1

   ;; Don't split the window for capture - use current window
   org-capture-bookmark nil)

  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (shell . t))))

;;;; Evil integration for capture and src-edit buffers

(when psyc-use-evil
  (defun psyc-org--capture-evil-binds ()
    "Set buffer-local evil ex commands for org-capture."
    (setq-local evil-ex-local-commands
                '(("w" . org-capture-finalize)
                  ("wq" . org-capture-finalize)
                  ("q" . org-capture-kill))))

  (defun psyc-org--src-edit-evil-binds ()
    "Set buffer-local evil ex commands for org-src-edit."
    (setq-local evil-ex-local-commands
                '(("w" . org-edit-src-save)
                  ("wq" . org-edit-src-exit)
                  ("q" . org-edit-src-abort))))

  (add-hook 'org-capture-mode-hook #'psyc-org--capture-evil-binds)
  (add-hook 'org-src-mode-hook #'psyc-org--src-edit-evil-binds))

;;;; Keybinds

(general-define-key
 :prefix-map 'psyc-notes-prefix-map
 "c" (cons "Capture" #'org-capture)
 "a" (cons "Agenda" #'org-agenda)
 "i" (cons "Open inbox" (psyc-cmd (find-file (concat psyc-org-dir "inbox.org"))))
 "t" (cons "Open todos" (psyc-cmd (find-file (concat psyc-org-dir "todo.org"))))
 "p" (cons "Open projects" (psyc-cmd (find-file (concat psyc-org-dir "projects.org"))))
 "n" (cons "Open notes" (psyc-cmd (find-file (concat psyc-org-dir "notes.org"))))
 "d" (cons "Dashboard" (psyc-cmd (org-agenda nil "d"))))

;; Modal integration: notes in space-map, local-leader for capture/src-edit
(with-eval-after-load 'psyc-modal
  (define-key psyc-modal-space-map "n" psyc-notes-prefix-map)

  (add-hook 'org-capture-mode-hook
            (lambda ()
              (setq psyc-modal-local-map (make-sparse-keymap "Capture"))
              (define-key psyc-modal-local-map "f" #'org-capture-finalize)
              (define-key psyc-modal-local-map "k" #'org-capture-kill)
              (define-key psyc-modal-local-map "r" #'org-capture-refile)))

  (add-hook 'org-src-mode-hook
            (lambda ()
              (setq psyc-modal-local-map (make-sparse-keymap "Src Edit"))
              (define-key psyc-modal-local-map "s" #'org-edit-src-save)
              (define-key psyc-modal-local-map "f" #'org-edit-src-exit)
              (define-key psyc-modal-local-map "k" #'org-edit-src-abort))))

(provide 'psyc-org)
;;; psyc-org.el ends here
