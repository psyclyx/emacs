;;; -*- lexical-binding: t -*-

(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 16 1024 1024))))

(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

(setq auto-mode-case-fold nil)

(let ((old-file-name-handler-alist file-name-handler-alist))
  (setq file-name-handler-alist (list (rassq 'jka-compr-handler file-name-handler-alist)))
  (add-hook 'after-init-hook
            (lambda () (setq file-name-handler-alist old-file-name-handler-alist))))

(setq native-comp-async-report-warnings-errors nil
      native-comp-jit-compilation t
      native-compile-prune-cache t)

(when (eq window-system 'pgtk)
  (setq pgtk-wait-for-event-timeout 0.001))

(unless (or (daemonp) init-file-debug)
  (push '(visibility . nil) initial-frame-alist)
  (add-hook 'emacs-startup-hook #'make-frame-visible))

(push '(menu-bar-lines . 0)   default-frame-alist)
(push '(tool-bar-lines . 0)   default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)

(setq load-prefer-newer noninteractive)

(setq-default inhibit-redisplay t
              inhibit-message (not init-file-debug)
              inhibit-x-resources t
              frame-inhibit-implied-resize t)

(defun psyc-init--reset-inhibited-vars-h ()
  (setq-default inhibit-redisplay nil inhibit-message nil)
  (remove-hook 'after-init-hook #'psyc-init--reset-inhibited-vars-h))
(add-hook 'after-init-hook #'psyc-init--reset-inhibited-vars-h -100)

(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-major-mode 'fundamental-mode
      initial-scratch-message nil)

(advice-add #'display-startup-echo-area-message :override #'ignore)
(advice-add #'display-startup-screen :override #'ignore)

(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil
      redisplay-skip-fontification-on-input t)
