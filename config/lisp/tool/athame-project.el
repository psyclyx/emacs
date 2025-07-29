;;; athame-project.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(defvar athame-project-marker ".project")

(use-package project
  :defer t
  :init
  (gsetq project-list-file (file-name-concat athame-state-dir "projects")
         project-vc-merge-submodules nil)
  :config
  (when athame-project-marker
    (add-to-list 'project-vc-extra-root-markers athame-project-marker)))

(defun athame--dir-locals-file ()
  (if (eq system-type 'ms-dos)
      (dosified-file-name dir-locals-file)
    dir-locals-file))

(defun athame--dir-locals-2-file ()
  (let ((dir-locals (athame--dir-locals-file)))
    (when (string-match "\\.el\\'" dir-locals)
      (replace-match "-2.el" t nil dir-locals))))

(defun athame-project-edit-dir-locals (&optional local)
  (interactive "P")
  (let* ((dir-locals-file (if local
                              (athame--dir-locals-2-file)
                            (athame--dir-locals-file)))
         (root (project-root (project-current t)))
         (expanded-file (expand-file-name dir-locals-file root)))
    (find-file expanded-file)))

(defun athame-project-find-file-in-other-project (project &optional include-all)
  (interactive (list (funcall project-prompter)) "P")
  (project--remember-dir project)
  (let ((project-current-directory-override project))
    (project-find-file include-all)))

(defun athame-project-create-marker (dir)
  "Create an empty file in `dir' so `project.el' can see it as a project."
  (interactive "D")
  (let ((marker-file (expand-file-name athame-project-marker dir)))
    (make-empty-file marker-file)))

(defun athame-consult-switch-project ()
  (interactive)
  (consult-buffer '(consult--source-project-root)))

(general-define-key
 :prefix-map 'athame-project-prefix-map
 "." (cons "Browse project" #'project-dired)
 "!" (cons "Run cmd in project root" #'project-shell-command)
 "&" (cons "Async cmd in project root" #'project-async-shell-command)
 "a" (cons "Discover projects in dir" #'project-remember-projects-under)
 "A" (cons "Create .project in dir" #'athame-project-create-marker)
 "b" (cons "Switch to project buffer" #'project-switch-to-buffer)
 "c" (cons "Compile in project" #'project-compile)
 "d" (cons "Forget project" #'project-forget-project)
 "D" (cons "Forget projects in dir" #'project-forget-projects-under)
 "e" (cons "Edit project .dir-locals" #'athame-project-edit-dir-locals)
 "p" (cons "Switch project" #'athame-consult-switch-project)
 "Z" (cons "Forget zombie projects" #'project-forget-zombie-projects)
 "f" (cons "Find file in project" #'project-find-file)
 "F" (cons "Find file in other project" #'athame-project-find-file-in-other-project))


;;; Provide
(provide 'athame-project)
;;; athame-project.el ends here
