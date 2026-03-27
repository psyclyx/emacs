;;; psyc-ai.el --- LLM integration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'psyc-lib)

;;;; Key management
;; Token file paths are injected via environment variables by the nix
;; hm-module (EMACS_ANTHROPIC_KEY_FILE, EMACS_OPENROUTER_KEY_FILE).
;; If the env vars are unset or files missing, backends silently skip setup.

(defun psyc-ai--read-key (env-var)
  "Read an API key from the file path stored in ENV-VAR."
  (when-let ((file (getenv env-var)))
    (when (file-readable-p file)
      (string-trim
       (with-temp-buffer
         (insert-file-contents file)
         (buffer-string))))))

;;;; gptel

(use-package gptel
  :defer t
  :init
  (gsetq gptel-default-mode 'org-mode)

  :config
  (when (getenv "EMACS_ANTHROPIC_KEY_FILE")
    (setq gptel-backend
          (gptel-make-anthropic "Claude"
            :stream t
            :key (lambda () (psyc-ai--read-key "EMACS_ANTHROPIC_KEY_FILE")))
          gptel-model 'claude-sonnet-4-20250514))

  (when (getenv "EMACS_OPENROUTER_KEY_FILE")
    (gptel-make-openai "OpenRouter"
      :host "openrouter.ai"
      :endpoint "/api/v1/chat/completions"
      :stream t
      :key (lambda () (psyc-ai--read-key "EMACS_OPENROUTER_KEY_FILE"))
      :models '(anthropic/claude-sonnet-4
                google/gemini-2.5-pro
                deepseek/deepseek-r1))))

;;;; Agent integration

(defun psyc-ai-claude-code ()
  "Launch Claude Code in the project root."
  (interactive)
  (let* ((default-directory
           (or (when-let ((proj (project-current)))
                 (project-root proj))
               default-directory))
         (buf (get-buffer "*claude-code*")))
    (if (and buf (get-buffer-process buf))
        (switch-to-buffer buf)
      (when buf (kill-buffer buf))
      (switch-to-buffer (make-term "claude-code" "claude"))
      (term-mode)
      (term-char-mode))))

;;;; Keybinds

(general-define-key
 :prefix-map 'psyc-ai-prefix-map
 "a" (cons "Chat" #'gptel)
 "s" (cons "Send" #'gptel-send)
 "r" (cons "Rewrite" #'gptel-rewrite)
 "m" (cons "Menu" #'gptel-menu)
 "k" (cons "Abort" #'gptel-abort)
 "c" (cons "Claude Code" #'psyc-ai-claude-code))

(provide 'psyc-ai)
;;; psyc-ai.el ends here
