;;; athame-init.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(defun athame-start--strip-gui ()
  "Quickly disables `menu-bar-mode', `tool-bar-lines', and `scroll-bar-mode'.
From doom."
   (push '(menu-bar-lines . 0)   default-frame-alist)
   (push '(tool-bar-lines . 0)   default-frame-alist)
   (push '(vertical-scroll-bars) default-frame-alist)
   (setq menu-bar-mode nil
         tool-bar-mode nil
         scroll-bar-mode nil))

(defun athame-start--inhibit-startup-redisplay ()
  "Prevent redisplays during startup.
From doom."
  (setq-default inhibit-redisplay t
                inhibit-message t
                frame-inhibit-implied-resize t)
  (defun athame--reset-inhibited-vars-h ()
    (setq-default inhibit-redisplay nil inhibit-message nil)
    (remove-hook 'post-command-hook #'athame--reset-inhibited-vars-h))
  (add-hook 'post-command-hook #'athame--reset-inhibited-vars-h -100))

(defun athame-start--simple-startup-screen ()
  "Disables the default initial start screen."
  (setq inhibit-startup-screen t
        inhibit-startup-echo-area-message user-login-name ; does this work?
        initial-major-mode 'fundamental-mode
        initial-scratch-message nil)
  (advice-add #'display-startup-echo-area-message :override #'ignore)
  (advice-add #'display-startup-screen :override #'ignore))

(defun athame-init-ui ()
  "Initialize the UI"
  (athame-start--strip-gui)
  (athame-start--inhibit-startup-redisplay)
  (athame-start--simple-startup-screen))

(provide 'athame-init)
