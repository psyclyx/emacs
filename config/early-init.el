(setq gc-cons-threshold (* 96 12 1024 1024))

(add-hook 'emacs-startup-hook
          (lambda ()
            (run-at-time "1" nil (lambda ()
                                   (setq gc-cons-threshold (* 12 1024 1024))))))


(setq inhibit-compacting-font-caches t)


(setq read-process-output-max (* 2 1024 1024))


(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)

(setq bidi-inhibit-bpa t)


(setq auto-mode-case-fold nil)
(defvar athame--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist athame-file-name-handler-alist)))


(setq native-comp-async-report-warnings-errors nil
      native-comp-jit-compilation t
      native-compile-prune-cache t)


(let ((default-directory (expand-file-name "lisp" user-emacs-directory)))
  (push default-directory load-path)
  (normal-top-level-add-subdirs-to-load-path))


(require 'athame-init)

(athame-init-ui)
