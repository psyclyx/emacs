;;; psyclyx-init.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code

(defvar psyclyx--gc-cons-threshold-high most-positive-fixnum)
(defvar psyclyx--gc-cons-threshold (* 96 1024 1024)) ;; 96 MB

(defun psyclyx--disable-gc ()
  (setq gc-cons-threshold psyclyx--gc-cons-threshold-high))

(defun psyclyx--enable-gc ()
  (setq gc-cons-threshold psyclyx--gc-cons-threshold))

(defun psyclyx--inhibit-file-name-handler ()
  (let ((file-name-handler-alist-cache file-name-handler-alist))
    (setq file-name-handler-alist nil)
    (add-hook 'emacs-startup-hook
              #'(lambda ()
                  (psyclyx-enable-gc)
                  (setq file-name-handler-alist file-name-handler-alist-cache)))))

(defun psyclyx-init ()
  (psyclyx--disable-gc)
  (psyclyx--inhibit-file-name-handler)
  (add-hook 'focus-out-hook #'garbage-collect))

(provide 'psyclyx-init)
