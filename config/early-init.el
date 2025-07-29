;;; -*- lexical-binding: t -*-
(set 'gc-cons-threshold most-positive-fixnum)

(add-hook 'emacs-startup-hook
          (lambda ()
            (run-at-time "2" nil (lambda () (set 'gc-cons-threshold (* 16 1024 1024))))))

(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(set 'bidi-inhibit-bpa t)

(set 'auto-mode-case-fold nil)

(let ((old-file-name-handler-alist file-name-handler-alist))
  (set 'file-name-handler-alist (list (rassq 'jka-compr-handler file-name-handler-alist)))
  (add-hook 'after-init-hook
            #'(lambda () (set 'file-name-handler-alist old-file-name-handler-alist))))

(set 'native-comp-speed 3)
(set 'native-comp-async-report-warnings-errors nil)
(set 'native-comp-jit-compilation t)
(set 'native-compile-prune-cache t)

(let* ((emacs-lisp-path (seq-find (lambda (s) (string-suffix-p "lisp/emacs-lisp" s)) load-path))
       (url-path (seq-find (lambda (s) (string-suffix-p "lisp/url" s)) load-path))
       (lisp-path (directory-file-name (file-name-directory emacs-lisp-path)))
       (old-load-path (mapcar #'copy-sequence load-path)))
  (when emacs-lisp-path
    (delete emacs-lisp-path load-path)
    (delete lisp-path load-path)
    (delete url-path load-path)
    (set 'load-path (append (list emacs-lisp-path lisp-path url-path) load-path))
    (add-hook 'after-init-hook #'(lambda ()(set 'load-path old-load-path)))))

(set 'pgtk-wait-for-event-timeout 0.0001)

(unless (or (daemonp) init-file-debug)
  (push '(visibility . nil) initial-frame-alist)
  (add-hook 'emacs-startup-hook #'make-frame-visible))

(push '(menu-bar-lines . 0)   default-frame-alist)
(push '(tool-bar-lines . 0)   default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(set 'menu-bar-mode nil)
(set 'tool-bar-mode nil)
(set 'scroll-bar-mode nil)

(set 'load-prefer-newer noninteractive)

(setq-default inhibit-redisplay t
              inhibit-message (not init-file-debug)
	      inhibit-x-resources t
              frame-inhibit-implied-resize t)

(defun athame-init--reset-inhibited-vars-h ()
  (setq-default inhibit-redisplay nil inhibit-message nil)
  (remove-hook 'after-init-hook #'athame-init--reset-inhibited-vars-h))
(add-hook 'after-init-hook #'athame-init--reset-inhibited-vars-h -100)

(set 'inhibit-startup-screen t)
(set 'inhibit-startup-echo-area-message user-login-name)
(set 'initial-major-mode 'fundamental-mode)
(set 'initial-scratch-message nil)

(advice-add #'display-startup-echo-area-message :override #'ignore)
(advice-add #'display-startup-screen :override #'ignore)

(setq-default cursor-in-non-selected-windows nil)
(set 'highlight-nonselected-windows nil)
(set 'redisplay-skip-fontification-on-input t)
