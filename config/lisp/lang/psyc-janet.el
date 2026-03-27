;;; psyc-janet.el --- Janet language support -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)
(require 'comint)

(defvar janet-repl-buffer-name "*janet-repl*")

(defun janet-repl ()
  "Start or switch to a Janet REPL."
  (interactive)
  (if (comint-check-proc janet-repl-buffer-name)
      (pop-to-buffer janet-repl-buffer-name)
    (let ((buf (make-comint-in-buffer "janet-repl" janet-repl-buffer-name "janet" nil)))
      (pop-to-buffer buf))))

(defun janet-repl-process ()
  "Return the Janet REPL process, starting one if needed."
  (or (get-buffer-process janet-repl-buffer-name)
      (progn (save-window-excursion (janet-repl))
             (get-buffer-process janet-repl-buffer-name))))

(defun janet-eval-region (start end)
  "Send region between START and END to the Janet REPL."
  (interactive "r")
  (comint-send-string (janet-repl-process)
                      (concat (buffer-substring-no-properties start end) "\n")))

(defun janet-eval-last-sexp ()
  "Send the sexp before point to the Janet REPL."
  (interactive)
  (janet-eval-region (save-excursion (backward-sexp) (point)) (point)))

(defun janet-eval-defun ()
  "Send the top-level form at point to the Janet REPL."
  (interactive)
  (save-excursion
    (end-of-defun)
    (let ((end (point)))
      (beginning-of-defun)
      (janet-eval-region (point) end))))

(defun janet-eval-buffer ()
  "Send the entire buffer to the Janet REPL."
  (interactive)
  (janet-eval-region (point-min) (point-max)))

(use-package janet-mode
  :mode "\\.janet\\'"
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(janet-mode "janet-lsp")))
  (with-eval-after-load 'apheleia
    (setf (alist-get 'janet-format apheleia-formatters) '("janet-format"))
    (setf (alist-get 'janet-mode apheleia-mode-alist) 'janet-format))

  (general-def
    :keymaps 'janet-mode-map
    [remap eval-last-sexp] #'janet-eval-last-sexp
    [remap eval-buffer] #'janet-eval-buffer
    [remap eval-region] #'janet-eval-region)

  (general-def
    :keymaps 'janet-mode-map
    :states 'normal
    :prefix "SPC m"

    "" '(:ignore t :which-key "janet")

    :infix "e"
    "" '(:ignore t :which-key "eval")
    "b" #'janet-eval-buffer
    "d" #'janet-eval-defun
    "e" #'janet-eval-last-sexp
    "r" #'janet-eval-region

    :infix "r"
    "" '(:ignore t :which-key "repl")
    "r" #'janet-repl))

(provide 'psyc-janet)
;;; psyc-janet.el ends here
