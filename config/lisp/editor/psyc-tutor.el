;;; psyc-tutor.el --- Interactive modal editing trainer -*- lexical-binding: t -*-

;;; Commentary:
;;
;; A typing-game-style trainer for psyc-modal.  Presents "transform A → B"
;; challenges and validates solutions using real psyc-modal commands.
;;
;; Keybindings are discovered dynamically from the live keymaps, so the
;; tutor adapts when bindings change.
;;
;; Usage:  M-x psyc-tutor          (start at level 1)
;;         C-u 3 M-x psyc-tutor   (start at level 3)
;;
;; Controls (in tutor buffer):
;;   C-c n  — skip challenge
;;   C-c r  — retry challenge
;;   C-c q  — quit tutor
;;   C-c +  — increase difficulty
;;   C-c -  — decrease difficulty
;;   C-c ?  — show session stats

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'psyc-modal)

;;;; --- Faces ---

(defface psyc-tutor-header
  '((t :inherit header-line :weight bold :height 1.1))
  "Header line face."
  :group 'psyc-modal)

(defface psyc-tutor-goal
  '((t :inherit default))
  "Goal text face."
  :group 'psyc-modal)

(defface psyc-tutor-goal-cursor
  '((t :inverse-video t))
  "Goal cursor indicator."
  :group 'psyc-modal)

(defface psyc-tutor-hint
  '((t :inherit font-lock-keyword-face :weight bold))
  "Hint keybind face."
  :group 'psyc-modal)

(defface psyc-tutor-description
  '((t :inherit font-lock-doc-face))
  "Challenge description face."
  :group 'psyc-modal)

(defface psyc-tutor-success
  '((t :inherit success :weight bold))
  "Success feedback."
  :group 'psyc-modal)

(defface psyc-tutor-diff
  '((t :inherit diff-removed))
  "Characters that still differ from goal."
  :group 'psyc-modal)

(defface psyc-tutor-timer
  '((t :inherit font-lock-comment-face))
  "Timer display."
  :group 'psyc-modal)

;;;; --- Data structures ---

(cl-defstruct (psyc-tutor-challenge (:constructor psyc-tutor-challenge--create))
  "A single transform-A-to-B challenge."
  (category   'movement :documentation "Symbol: movement, editing, text-object, surround, structural, multi-step")
  (difficulty 1         :documentation "Integer 1-5")
  (start-text ""        :documentation "Initial buffer contents")
  (start-point 1        :documentation "Initial cursor position (1-indexed)")
  (goal-text  ""        :documentation "Desired buffer contents")
  (goal-point 1         :documentation "Desired cursor position")
  (hint-keys  nil       :documentation "List of key strings for the solution")
  (description ""       :documentation "What the user should do")
  (setup-fn   nil       :documentation "Function called before challenge starts")
  (goal-state 'normal   :documentation "Expected psyc-modal state after completion"))

(cl-defstruct (psyc-tutor-stats (:constructor psyc-tutor-stats--create))
  "Per-challenge performance tracking."
  (attempts 0)
  (successes 0)
  (best-time nil)
  (streak 0))

(cl-defstruct (psyc-tutor-session (:constructor psyc-tutor-session--create))
  "Active tutoring session."
  (challenges   []      :documentation "Vector of challenges")
  (current-idx  0       :documentation "Index into challenges")
  (difficulty   1       :documentation "Current difficulty 1-5")
  (show-hints-p t       :documentation "Whether to show keybind hints")
  (stats        nil     :documentation "Hash-table: index -> psyc-tutor-stats")
  (start-time   0.0     :documentation "Timestamp for current challenge")
  (hint-timer   nil     :documentation "Timer for hint reveal")
  (completed    0       :documentation "Number of challenges completed")
  (window-config nil    :documentation "Window config before tutor started"))

;;;; --- Session state ---

(defvar-local psyc-tutor--session nil "Active session in this buffer.")
(defvar-local psyc-tutor--edit-start nil "Marker for start of editable region.")
(defvar-local psyc-tutor--goal-buffer nil "The goal display buffer.")

(defconst psyc-tutor--edit-buf-name "*psyc-tutor*")
(defconst psyc-tutor--goal-buf-name "*psyc-tutor-goal*")
(defconst psyc-tutor--reference-buf-name "*psyc-modal quick ref*")

;;;; --- Difficulty config ---

(defvar psyc-tutor-difficulty-config
  '((1 . (:show-hints t   :timeout nil  :label "Guided"))
    (2 . (:show-hints t   :timeout 15.0 :label "Timed"))
    (3 . (:show-hints nil  :timeout 10.0 :label "Recall"))
    (4 . (:show-hints nil  :timeout 6.0  :label "Speed"))
    (5 . (:show-hints nil  :timeout 4.0  :label "Mastery")))
  "Per-level configuration for hint display and timeout.")

(defun psyc-tutor--diff-config (level key)
  "Get KEY from difficulty config for LEVEL."
  (plist-get (alist-get level psyc-tutor-difficulty-config) key))

;;;; --- Keymap introspection ---

(defun psyc-tutor--collect-bindings (keymap &optional prefix)
  "Walk KEYMAP, return alist of (KEY-STRING . COMMAND).
Sub-keymaps are recursed with PREFIX prepended."
  (let (bindings)
    (map-keymap
     (lambda (event binding)
       (let ((key-str (concat (or prefix "")
                              (key-description (vector event)))))
         (cond
          ((commandp binding)
           (push (cons key-str binding) bindings))
          ((keymapp binding)
           (setq bindings
                 (nconc (psyc-tutor--collect-bindings binding
                                                      (concat key-str " "))
                        bindings))))))
     keymap)
    (nreverse bindings)))

(defun psyc-tutor--key-for-command (cmd &optional keymap)
  "Return the key string bound to CMD in KEYMAP (default: normal-map)."
  (when-let ((keys (where-is-internal cmd (or keymap psyc-modal-normal-map) t)))
    (key-description keys)))

(defun psyc-tutor--reference-key (cmd)
  "Return a display key for CMD."
  (or (psyc-tutor--key-for-command cmd)
      (symbol-name cmd)))

(defun psyc-tutor--reference-prefix (cmd suffix)
  "Return the CMD binding followed by SUFFIX."
  (string-join (list (psyc-tutor--reference-key cmd) suffix) " "))

(defun psyc-tutor--reference-alt (&rest keys)
  "Join KEYS as alternatives for display."
  (string-join keys " / "))

(defun psyc-tutor--reference-seq (&rest keys)
  "Join KEYS as a sequential command pattern."
  (string-join keys " "))

(defun psyc-tutor--insert-reference-section (title rows)
  "Insert a reference section titled TITLE with ROWS."
  (let ((width (apply #'max 0 (mapcar (lambda (row) (length (car row))) rows))))
    (insert (propertize title 'face 'bold) "\n")
    (dolist (row rows)
      (insert "  "
              (propertize (format (format "%%-%ds" width) (car row))
                          'face 'help-key-binding)
              "  "
              (cdr row)
              "\n"))
    (insert "\n")))

(defvar psyc-tutor-reference-mode-map
  (let ((m (make-sparse-keymap)))
    (set-keymap-parent m special-mode-map)
    (define-key m "t" #'psyc-tutor)
    (define-key m "g" #'psyc-tutor-quick-reference)
    m)
  "Keymap for `psyc-tutor-reference-mode'.")

(define-derived-mode psyc-tutor-reference-mode special-mode "Tutor Ref"
  "Quick reference for psyc-modal editing patterns."
  (setq-local truncate-lines t))

;;;; --- Command classification ---

(defvar psyc-tutor--movement-commands
  '((psyc-modal-word-next       . "Jump to the next word start")
    (psyc-modal-word-back       . "Jump back to the previous word start")
    (psyc-modal-word-end        . "Jump to the end of the current word")
    (psyc-modal-WORD-next       . "Jump to the next WORD start (whitespace-delimited)")
    (psyc-modal-WORD-back       . "Jump back to the previous WORD start")
    (psyc-modal-WORD-end        . "Jump to the end of the current WORD")
    (psyc-modal-goto-file-start . "Go to the very beginning of the buffer")
    (psyc-modal-goto-file-end   . "Go to the very end of the buffer")
    (psyc-modal-goto-line-start . "Go to the beginning of the line")
    (psyc-modal-goto-line-end   . "Go to the end of the line")
    (psyc-modal-goto-first-nonblank . "Go to the first non-blank character on the line")
    (psyc-modal-forward-sexp    . "Jump forward over the next s-expression")
    (psyc-modal-backward-sexp   . "Jump backward over the previous s-expression"))
  "Movement commands and their descriptions for challenge generation.")

(defvar psyc-tutor--sample-texts
  '("(defun greet (name)\n  (message \"Hello, %s!\" name))\n\n(defun add (a b)\n  (+ a b))"
    "The quick brown fox jumps over the lazy dog.\nPack my box with five dozen liquor jugs."
    "fn main() {\n    let x = 42;\n    println!(\"value: {}\", x);\n}"
    "one two three four five\nsix seven eight nine ten\neleven twelve thirteen")
  "Sample texts for auto-generated challenges.")

;;;; --- Challenge generation (movements) ---

(defun psyc-tutor--generate-movement (cmd desc sample-text start-pos)
  "Generate a movement challenge for CMD from START-POS in SAMPLE-TEXT.
DESC is the human-readable description.
Returns a challenge struct, or nil if the command doesn't move point."
  (let (goal-point)
    (with-temp-buffer
      (insert sample-text)
      (goto-char (min start-pos (point-max)))
      (psyc-modal-mode 1)
      (psyc-modal-enter-normal)
      (ignore-errors (call-interactively cmd))
      (setq goal-point (point)))
    (when (and goal-point (/= start-pos goal-point)
               (<= goal-point (1+ (length sample-text))))
      (let ((key (psyc-tutor--key-for-command cmd)))
        (when key
          (psyc-tutor-challenge--create
           :category 'movement
           :difficulty 1
           :start-text sample-text
           :start-point start-pos
           :goal-text sample-text
           :goal-point goal-point
           :hint-keys (list key)
           :description desc))))))

(defun psyc-tutor--generate-movement-challenges ()
  "Auto-generate movement challenges from bound commands."
  (let (challenges)
    (pcase-dolist (`(,cmd . ,desc) psyc-tutor--movement-commands)
      (when (psyc-tutor--key-for-command cmd)
        (dolist (text psyc-tutor--sample-texts)
          ;; Try a few starting positions per text
          (dolist (start-pos (list 1 8 15 (max 1 (/ (length text) 2))))
            (when-let ((ch (psyc-tutor--generate-movement cmd desc text start-pos)))
              (push ch challenges))))))
    (nreverse challenges)))

;;;; --- Hand-crafted challenge bank ---

(defun psyc-tutor--builtin-challenges ()
  "Return list of hand-crafted challenges."
  (list
   ;; --- Level 1: Basic movements ---
   (psyc-tutor-challenge--create
    :category 'movement :difficulty 1
    :start-text "hello world" :start-point 1
    :goal-text "hello world" :goal-point 7
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-word-next) "w"))
    :description "Move to the next word")

   (psyc-tutor-challenge--create
    :category 'movement :difficulty 1
    :start-text "hello world foo" :start-point 7
    :goal-text "hello world foo" :goal-point 1
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-goto-line-start) "g h"))
    :description "Go to the start of the line")

   (psyc-tutor-challenge--create
    :category 'movement :difficulty 1
    :start-text "one two three four" :start-point 1
    :goal-text "one two three four" :goal-point 18
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-goto-line-end) "g l"))
    :description "Go to the end of the line")

   (psyc-tutor-challenge--create
    :category 'movement :difficulty 1
    :start-text "foo, bar, baz" :start-point 1
    :goal-text "foo, bar, baz" :goal-point 4
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-find-forward) "f") ",")
    :description "Find the comma")

   (psyc-tutor-challenge--create
    :category 'movement :difficulty 1
    :start-text "foo, bar, baz" :start-point 1
    :goal-text "foo, bar, baz" :goal-point 3
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-till-forward) "t") ",")
    :description "Move up to (but not on) the comma")

   (psyc-tutor-challenge--create
    :category 'movement :difficulty 1
    :start-text "first\nsecond\nthird" :start-point 1
    :goal-text "first\nsecond\nthird" :goal-point 13
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-goto-file-end) "g e"))
    :description "Go to the end of the buffer")

   ;; --- Level 2: Selection + single action ---
   (psyc-tutor-challenge--create
    :category 'editing :difficulty 2
    :start-text "hello cruel world" :start-point 7
    :goal-text "hello world" :goal-point 7
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-word-next) "w")
                     (or (psyc-tutor--key-for-command 'psyc-modal-delete) "d"))
    :description "Delete the word under the cursor")

   (psyc-tutor-challenge--create
    :category 'editing :difficulty 2
    :start-text "aaa bbb ccc" :start-point 5
    :goal-text "aaa ccc" :goal-point 5
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-word-next) "w")
                     (or (psyc-tutor--key-for-command 'psyc-modal-delete) "d"))
    :description "Delete the word under the cursor")

   (psyc-tutor-challenge--create
    :category 'editing :difficulty 2
    :start-text "hello world" :start-point 1
    :goal-text "hello world" :goal-point 1
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-select-line) "x")
                     (or (psyc-tutor--key-for-command 'psyc-modal-yank) "y"))
    :description "Select the current line and yank (copy) it")

   (psyc-tutor-challenge--create
    :category 'editing :difficulty 2
    :start-text "line one\nline two\nline three" :start-point 10
    :goal-text "line one\nline three" :goal-point 10
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-select-line) "x")
                     (or (psyc-tutor--key-for-command 'psyc-modal-delete) "d"))
    :description "Delete the current line")

   (psyc-tutor-challenge--create
    :category 'editing :difficulty 2
    :start-text "Hello World" :start-point 1
    :goal-text "hello world" :goal-point 1
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-select-all) "%")
                     "~")
    :description "Toggle the case of the entire buffer")

   (psyc-tutor-challenge--create
    :category 'editing :difficulty 2
    :start-text "one\ntwo" :start-point 1
    :goal-text "one two" :goal-point 4
    :hint-keys (list "J")
    :description "Join the two lines")

   ;; --- Level 2: Insert mode ---
   (psyc-tutor-challenge--create
    :category 'editing :difficulty 2
    :start-text "hllo" :start-point 2
    :goal-text "hello" :goal-point 2
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-insert-before) "i")
                     "e" "<escape>")
    :description "Insert the missing 'e'"
    :goal-state 'normal)

   (psyc-tutor-challenge--create
    :category 'editing :difficulty 2
    :start-text "hello" :start-point 5
    :goal-text "hello world" :goal-point 10
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-insert-eol) "A")
                     " world" "<escape>")
    :description "Append ' world' to the end of the line"
    :goal-state 'normal)

   (psyc-tutor-challenge--create
    :category 'editing :difficulty 2
    :start-text "first\nthird" :start-point 1
    :goal-text "first\nsecond\nthird" :goal-point 11
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-open-below) "o")
                     "second" "<escape>")
    :description "Open a line below and type 'second'"
    :goal-state 'normal)

   ;; --- Level 3: Text objects ---
   (psyc-tutor-challenge--create
    :category 'text-object :difficulty 3
    :start-text "(hello world)" :start-point 5
    :goal-text "()" :goal-point 1
    :hint-keys (list "m" "i" "(" (or (psyc-tutor--key-for-command 'psyc-modal-delete) "d"))
    :description "Delete inside the parentheses")

   (psyc-tutor-challenge--create
    :category 'text-object :difficulty 3
    :start-text "say \"goodbye\"" :start-point 7
    :goal-text "say \"hello\"" :goal-point 5
    :hint-keys (list "m" "i" "\"" (or (psyc-tutor--key-for-command 'psyc-modal-change) "c")
                     "hello" "<escape>")
    :description "Change the text inside the quotes to 'hello'"
    :goal-state 'normal)

   (psyc-tutor-challenge--create
    :category 'text-object :difficulty 3
    :start-text "[1 2 3]" :start-point 3
    :goal-text "1 2 3" :goal-point 1
    :hint-keys (list "m" "a" "[" (or (psyc-tutor--key-for-command 'psyc-modal-delete) "d"))
    :description "Delete around the brackets (including them)")

   (psyc-tutor-challenge--create
    :category 'text-object :difficulty 3
    :start-text "one two three" :start-point 5
    :goal-text "one THREE three" :goal-point 5
    :hint-keys (list "m" "i" "w" (or (psyc-tutor--key-for-command 'psyc-modal-change) "c")
                     "THREE" "<escape>")
    :description "Change the word under the cursor to 'THREE'"
    :goal-state 'normal)

   ;; --- Level 3: Surround ---
   (psyc-tutor-challenge--create
    :category 'surround :difficulty 3
    :start-text "hello" :start-point 1
    :goal-text "(hello)" :goal-point 1
    :hint-keys (list (or (psyc-tutor--key-for-command 'psyc-modal-select-all) "%")
                     "m" "s" "(")
    :description "Surround the entire buffer with parentheses")

   (psyc-tutor-challenge--create
    :category 'surround :difficulty 3
    :start-text "(hello)" :start-point 3
    :goal-text "hello" :goal-point 1
    :hint-keys (list "m" "d" "(")
    :description "Delete the surrounding parentheses")

   (psyc-tutor-challenge--create
    :category 'surround :difficulty 3
    :start-text "(hello)" :start-point 3
    :goal-text "[hello]" :goal-point 3
    :hint-keys (list "m" "r" "(" "[")
    :description "Replace the surrounding parens with brackets")

   ;; --- Level 3-4: Structural editing ---
   (psyc-tutor-challenge--create
    :category 'structural :difficulty 3
    :start-text "(a b) c" :start-point 3
    :goal-text "(a b c)" :goal-point 3
    :hint-keys (list "m" ")")
    :description "Slurp the next element into the list")

   (psyc-tutor-challenge--create
    :category 'structural :difficulty 3
    :start-text "(a b c)" :start-point 3
    :goal-text "(a b) c" :goal-point 3
    :hint-keys (list "m" "}")
    :description "Barf the last element out of the list")

   (psyc-tutor-challenge--create
    :category 'structural :difficulty 3
    :start-text "(a (b c) d)" :start-point 5
    :goal-text "(a b c d)" :goal-point 4
    :hint-keys (list "m" "S")
    :description "Splice — remove the inner parentheses")

   (psyc-tutor-challenge--create
    :category 'structural :difficulty 4
    :start-text "(a (b c) d)" :start-point 8
    :goal-text "(a c d)" :goal-point 4
    :hint-keys (list "m" "R")
    :description "Raise — replace the inner list with the sexp at point")

   ;; --- Level 4: Multi-step combos ---
   (psyc-tutor-challenge--create
    :category 'multi-step :difficulty 4
    :start-text "foo bar baz" :start-point 1
    :goal-text "baz bar foo" :goal-point 9
    :hint-keys (list "w" "d" "g" "l" "p" "g" "h" "P")
    :description "Swap the first and last words")

   (psyc-tutor-challenge--create
    :category 'multi-step :difficulty 4
    :start-text "one\ntwo\nthree" :start-point 5
    :goal-text "one\nthree" :goal-point 5
    :hint-keys (list "x" "d")
    :description "Delete the current line")

   (psyc-tutor-challenge--create
    :category 'multi-step :difficulty 4
    :start-text "hello world" :start-point 1
    :goal-text "Hello World" :goal-point 1
    :hint-keys (list "~" "w" "~")
    :description "Capitalize the first letter of each word")

   (psyc-tutor-challenge--create
    :category 'multi-step :difficulty 4
    :start-text "(defn foo [x]\n  (+ x 1))" :start-point 7
    :goal-text "(defn bar [x]\n  (+ x 1))" :goal-point 7
    :hint-keys (list "m" "i" "w" "c" "bar" "<escape>")
    :description "Rename the function from 'foo' to 'bar'"
    :goal-state 'normal)

   (psyc-tutor-challenge--create
    :category 'multi-step :difficulty 4
    :start-text "let x = value;" :start-point 9
    :goal-text "let x = (value);" :goal-point 9
    :hint-keys (list "m" "i" "w" "m" "s" "(")
    :description "Wrap the word in parentheses")

   ;; --- Level 5: Complex chains ---
   (psyc-tutor-challenge--create
    :category 'multi-step :difficulty 5
    :start-text "(if true\n  (do-a)\n  (do-b))" :start-point 16
    :goal-text "(when true\n  (do-a))" :goal-point 1
    :hint-keys (list "x" "x" "d" "g" "g" "m" "i" "w" "c" "when" "<escape>")
    :description "Change 'if' to 'when' and remove the else branch"
    :goal-state 'normal)

   (psyc-tutor-challenge--create
    :category 'multi-step :difficulty 5
    :start-text "a b c d e" :start-point 1
    :goal-text "(a) (b) (c) (d) (e)" :goal-point 1
    :hint-keys (list "m" "w" "m" "s" "(" "w" "." "w" "." "w" "." "w" ".")
    :description "Wrap each word in parentheses using repeat (.)")
   ))

;;;; --- Challenge pool ---

(defun psyc-tutor--all-challenges ()
  "Build the full challenge pool: auto-generated + hand-crafted."
  (let ((auto (psyc-tutor--generate-movement-challenges))
        (builtin (psyc-tutor--builtin-challenges)))
    ;; Remove auto-generated duplicates that are too similar
    (let ((filtered-auto
           (cl-remove-if
            (lambda (ch)
              (or (= (psyc-tutor-challenge-start-point ch)
                     (psyc-tutor-challenge-goal-point ch))
                  ;; Skip if movement is trivially small
                  (< (abs (- (psyc-tutor-challenge-goal-point ch)
                             (psyc-tutor-challenge-start-point ch)))
                     2)))
            auto)))
      ;; Limit auto-generated to avoid overwhelming
      (append (seq-take (psyc-tutor--shuffle filtered-auto) 20)
              builtin))))

(defun psyc-tutor--shuffle (list)
  "Return a shuffled copy of LIST."
  (let ((vec (vconcat list)))
    (cl-loop for i from (1- (length vec)) downto 1
             do (let* ((j (random (1+ i)))
                       (tmp (aref vec i)))
                  (aset vec i (aref vec j))
                  (aset vec j tmp)))
    (append vec nil)))

;;;; --- Goal buffer rendering ---

(defun psyc-tutor--goal-buffer ()
  "Get or create the goal display buffer."
  (get-buffer-create psyc-tutor--goal-buf-name))

(defun psyc-tutor--render-goal (session challenge)
  "Render the goal display for CHALLENGE in SESSION."
  (with-current-buffer (psyc-tutor--goal-buffer)
    (let ((inhibit-read-only t)
          (diff-cfg (alist-get (psyc-tutor-session-difficulty session)
                               psyc-tutor-difficulty-config))
          (completed (psyc-tutor-session-completed session))
          (total (length (psyc-tutor-session-challenges session))))
      (erase-buffer)
      ;; Header
      (insert (propertize
               (format " PSYC TUTOR  Level %d: %s   %d/%d\n\n"
                       (psyc-tutor-session-difficulty session)
                       (plist-get diff-cfg :label)
                       (1+ completed) total)
               'face 'psyc-tutor-header))
      ;; Goal text
      (insert (propertize " GOAL:\n" 'face 'psyc-tutor-description))
      (let ((goal-start (point))
            (goal-text (psyc-tutor-challenge-goal-text challenge))
            (goal-point (psyc-tutor-challenge-goal-point challenge)))
        ;; Insert goal with indentation
        (dolist (line (split-string goal-text "\n"))
          (insert " " line "\n"))
        ;; Mark the goal cursor position
        (let ((cursor-pos (+ goal-start goal-point)))
          (when (<= cursor-pos (point-max))
            (let ((ov (make-overlay cursor-pos (min (1+ cursor-pos) (point-max)))))
              (overlay-put ov 'face 'psyc-tutor-goal-cursor)
              (overlay-put ov 'psyc-tutor t)))))
      ;; Description
      (insert "\n")
      (insert (propertize (format " %s\n" (psyc-tutor-challenge-description challenge))
                          'face 'psyc-tutor-description))
      ;; Hints
      (insert " ")
      (if (plist-get diff-cfg :show-hints)
          (psyc-tutor--insert-hints (psyc-tutor-challenge-hint-keys challenge))
        (insert (propertize "[hints hidden]" 'face 'psyc-tutor-timer)))
      ;; Timer placeholder
      (insert (propertize "      0.0s" 'face 'psyc-tutor-timer))
      (insert "\n")
      (setq buffer-read-only t))))

(defun psyc-tutor--insert-hints (hint-keys)
  "Insert formatted HINT-KEYS into the current buffer."
  (insert (propertize "[" 'face 'psyc-tutor-timer))
  (let ((first t))
    (dolist (k hint-keys)
      (unless first (insert " "))
      (insert (propertize k 'face 'psyc-tutor-hint))
      (setq first nil)))
  (insert (propertize "]" 'face 'psyc-tutor-timer)))

(defun psyc-tutor--update-timer (session)
  "Update the timer display in the goal buffer."
  (let ((elapsed (- (float-time) (psyc-tutor-session-start-time session))))
    (with-current-buffer (psyc-tutor--goal-buffer)
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (point-max))
          (when (re-search-backward "[0-9]+\\.[0-9]s" nil t)
            (replace-match (format "%.1fs" elapsed))))))))

(defun psyc-tutor--reveal-hints (session)
  "Reveal hints in the goal buffer after timeout."
  (when (and session (buffer-live-p (psyc-tutor--goal-buffer)))
    (let ((challenge (aref (psyc-tutor-session-challenges session)
                           (psyc-tutor-session-current-idx session))))
      (with-current-buffer (psyc-tutor--goal-buffer)
        (let ((inhibit-read-only t))
          (save-excursion
            (goto-char (point-min))
            (when (search-forward "[hints hidden]" nil t)
              (let ((beg (match-beginning 0))
                    (end (match-end 0)))
                (delete-region beg end)
                (goto-char beg)
                (psyc-tutor--insert-hints
                 (psyc-tutor-challenge-hint-keys challenge))))))))))

;;;; --- Diff overlay in goal buffer ---

(defun psyc-tutor--update-goal-diff (current-text challenge)
  "Update diff overlays in the goal buffer based on CURRENT-TEXT vs goal."
  (with-current-buffer (psyc-tutor--goal-buffer)
    ;; Remove old diff overlays
    (dolist (ov (overlays-in (point-min) (point-max)))
      (when (overlay-get ov 'psyc-tutor-diff)
        (delete-overlay ov)))
    ;; Find the goal text region
    (save-excursion
      (goto-char (point-min))
      (when (search-forward "GOAL:\n" nil t)
        (let* ((goal-text (psyc-tutor-challenge-goal-text challenge))
               (goal-start (point))
               ;; Compare character by character
               (max-i (min (length current-text) (length goal-text))))
          ;; Highlight differences
          (dotimes (i max-i)
            (unless (= (aref current-text i)
                       (aref goal-text i))
              ;; +1 for the leading space on each line
              (let* ((line-num (cl-count ?\n (substring goal-text 0 i)))
                     (adj-pos (+ goal-start i 1 line-num)))
                (when (<= adj-pos (point-max))
                  (let ((ov (make-overlay adj-pos (1+ adj-pos))))
                    (overlay-put ov 'psyc-tutor-diff t)
                    (overlay-put ov 'face 'psyc-tutor-diff)))))))))))

;;;; --- Window layout ---

(defun psyc-tutor--setup-windows ()
  "Set up a side-by-side layout: goal (left) + edit (right)."
  (delete-other-windows)
  ;; Left: goal buffer
  (switch-to-buffer (psyc-tutor--goal-buffer))
  (set-window-dedicated-p (selected-window) t)
  ;; Right: edit buffer
  (let ((edit-win (split-window-right)))
    (select-window edit-win)
    (switch-to-buffer (get-buffer-create psyc-tutor--edit-buf-name))))

;;;; --- Mode definition ---

(defvar psyc-tutor-control-map
  (let ((m (make-sparse-keymap)))
    (define-key m "n" #'psyc-tutor-skip)
    (define-key m "r" #'psyc-tutor-retry)
    (define-key m "q" #'psyc-tutor-quit)
    (define-key m "+" #'psyc-tutor-increase-difficulty)
    (define-key m "-" #'psyc-tutor-decrease-difficulty)
    (define-key m "?" #'psyc-tutor-show-stats)
    m)
  "Control keymap for tutor meta-commands.")

(define-derived-mode psyc-tutor-mode fundamental-mode "Tutor"
  "Interactive training mode for psyc-modal."
  :group 'psyc-modal
  (define-key psyc-tutor-mode-map "\C-c" psyc-tutor-control-map)
  (psyc-modal-mode 1)
  (add-hook 'post-command-hook #'psyc-tutor--post-command nil t))

;;;; --- Session management ---

(defun psyc-tutor--mastered-p (stats)
  "Return non-nil if STATS indicate mastery."
  (and stats
       (>= (psyc-tutor-stats-streak stats) 3)))

(defun psyc-tutor--select-next (session)
  "Select the next challenge index for SESSION.
Prioritizes unmastered challenges at or below current difficulty."
  (let* ((challenges (psyc-tutor-session-challenges session))
         (difficulty (psyc-tutor-session-difficulty session))
         (stats (psyc-tutor-session-stats session))
         (candidates nil))
    ;; Collect eligible challenge indices
    (cl-loop for i below (length challenges)
             for ch = (aref challenges i)
             when (<= (psyc-tutor-challenge-difficulty ch) difficulty)
             do (unless (psyc-tutor--mastered-p (gethash i stats))
                  (push i candidates)))
    ;; If all mastered at this level, include mastered ones too
    (unless candidates
      (cl-loop for i below (length challenges)
               for ch = (aref challenges i)
               when (<= (psyc-tutor-challenge-difficulty ch) difficulty)
               do (push i candidates)))
    (when candidates
      (nth (random (length candidates)) candidates))))

(defun psyc-tutor--load-challenge (session)
  "Load the current challenge into the edit buffer."
  (let* ((idx (psyc-tutor-session-current-idx session))
         (challenge (aref (psyc-tutor-session-challenges session) idx)))
    ;; Cancel any pending hint timer
    (when (psyc-tutor-session-hint-timer session)
      (cancel-timer (psyc-tutor-session-hint-timer session))
      (setf (psyc-tutor-session-hint-timer session) nil))
    ;; Set up edit buffer
    (with-current-buffer (get-buffer-create psyc-tutor--edit-buf-name)
      (let ((inhibit-read-only t))
        (erase-buffer)
        ;; Run setup function if any
        (when (psyc-tutor-challenge-setup-fn challenge)
          (funcall (psyc-tutor-challenge-setup-fn challenge)))
        ;; Insert start text
        (insert (psyc-tutor-challenge-start-text challenge))
        (goto-char (psyc-tutor-challenge-start-point challenge))
        ;; Reset undo
        (setq buffer-undo-list nil)
        ;; Ensure normal state
        (psyc-modal-enter-normal)))
    ;; Render goal
    (psyc-tutor--render-goal session challenge)
    ;; Start timer
    (setf (psyc-tutor-session-start-time session) (float-time))
    ;; Schedule hint reveal
    (let ((timeout (psyc-tutor--diff-config
                    (psyc-tutor-session-difficulty session) :timeout)))
      (when (and timeout (not (psyc-tutor--diff-config
                               (psyc-tutor-session-difficulty session) :show-hints)))
        (setf (psyc-tutor-session-hint-timer session)
              (run-with-timer timeout nil #'psyc-tutor--reveal-hints session))))))

;;;; --- Completion detection ---

(defun psyc-tutor--post-command ()
  "Check challenge completion after each command."
  (when-let ((session psyc-tutor--session))
    (let* ((idx (psyc-tutor-session-current-idx session))
           (challenge (aref (psyc-tutor-session-challenges session) idx))
           (current-text (buffer-substring-no-properties (point-min) (point-max)))
           (current-point (point))
           (goal-state (psyc-tutor-challenge-goal-state challenge)))
      ;; Update diff display
      (psyc-tutor--update-goal-diff current-text challenge)
      ;; Update timer
      (psyc-tutor--update-timer session)
      ;; Check completion
      (when (and (string= current-text (psyc-tutor-challenge-goal-text challenge))
                 (= current-point (psyc-tutor-challenge-goal-point challenge))
                 (eq psyc-modal--state goal-state))
        (psyc-tutor--challenge-success session)))))

(defun psyc-tutor--challenge-success (session)
  "Handle successful challenge completion."
  (let* ((idx (psyc-tutor-session-current-idx session))
         (elapsed (- (float-time) (psyc-tutor-session-start-time session)))
         (stats-table (psyc-tutor-session-stats session))
         (stats (or (gethash idx stats-table)
                    (psyc-tutor-stats--create))))
    ;; Cancel hint timer
    (when (psyc-tutor-session-hint-timer session)
      (cancel-timer (psyc-tutor-session-hint-timer session))
      (setf (psyc-tutor-session-hint-timer session) nil))
    ;; Update stats
    (cl-incf (psyc-tutor-stats-attempts stats))
    (cl-incf (psyc-tutor-stats-successes stats))
    (cl-incf (psyc-tutor-stats-streak stats))
    (setf (psyc-tutor-stats-best-time stats)
          (if (psyc-tutor-stats-best-time stats)
              (min elapsed (psyc-tutor-stats-best-time stats))
            elapsed))
    (puthash idx stats stats-table)
    (cl-incf (psyc-tutor-session-completed session))
    ;; Flash success
    (psyc-tutor--flash-success elapsed)
    ;; Advance to next after brief delay
    (run-with-timer 0.8 nil #'psyc-tutor--advance session)))

(defun psyc-tutor--flash-success (elapsed)
  "Show success feedback with ELAPSED time."
  (with-current-buffer (psyc-tutor--goal-buffer)
    (let ((inhibit-read-only t))
      (save-excursion
        (goto-char (point-max))
        (insert (propertize (format "\n  %.1fs" elapsed)
                            'face 'psyc-tutor-success))))))

(defun psyc-tutor--advance (session)
  "Move to the next challenge in SESSION."
  (when (and session (buffer-live-p (get-buffer psyc-tutor--edit-buf-name)))
    (with-current-buffer (get-buffer psyc-tutor--edit-buf-name)
      (let ((next-idx (psyc-tutor--select-next session)))
        (if next-idx
            (progn
              (setf (psyc-tutor-session-current-idx session) next-idx)
              (psyc-tutor--load-challenge session))
          (psyc-tutor--session-complete session))))))

(defun psyc-tutor--session-complete (session)
  "Handle session completion — all challenges mastered."
  (with-current-buffer (psyc-tutor--goal-buffer)
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (propertize "\n All challenges mastered at this level!\n\n"
                          'face 'psyc-tutor-success))
      (insert (format " Completed: %d\n" (psyc-tutor-session-completed session)))
      (insert "\n C-c + to increase difficulty, C-c q to quit\n"))))

;;;; --- User commands ---

(defun psyc-tutor-quick-reference ()
  "Show a quick reference for psyc-modal editing patterns."
  (interactive)
  (let ((buf (get-buffer-create psyc-tutor--reference-buf-name)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (psyc-tutor-reference-mode)
        (insert (propertize "PSYC Modal Quick Reference\n" 'face 'header-line)
                "\n")
        (insert "Selection-first editing: movements create a selection, then actions like "
                (propertize "d" 'face 'help-key-binding)
                ", "
                (propertize "c" 'face 'help-key-binding)
                ", and "
                (propertize "y" 'face 'help-key-binding)
                " consume it.\n\n")
        (psyc-tutor--insert-reference-section
         "Move"
         (list
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-left)
                 (psyc-tutor--reference-key 'psyc-modal-down)
                 (psyc-tutor--reference-key 'psyc-modal-up)
                 (psyc-tutor--reference-key 'psyc-modal-right))
                "move by character")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-word-next)
                 (psyc-tutor--reference-key 'psyc-modal-word-back)
                 (psyc-tutor--reference-key 'psyc-modal-word-end))
                "word start / back / end")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-WORD-next)
                 (psyc-tutor--reference-key 'psyc-modal-WORD-back)
                 (psyc-tutor--reference-key 'psyc-modal-WORD-end))
                "WORD motions")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-prefix 'psyc-modal-find-forward "x")
                 (psyc-tutor--reference-prefix 'psyc-modal-till-forward "x")
                 (psyc-tutor--reference-prefix 'psyc-modal-find-backward "x")
                 (psyc-tutor--reference-prefix 'psyc-modal-till-backward "x"))
                "find / till a character on the line")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-goto-line-start)
                 (psyc-tutor--reference-key 'psyc-modal-goto-line-end)
                 (psyc-tutor--reference-key 'psyc-modal-goto-file-start)
                 (psyc-tutor--reference-key 'psyc-modal-goto-file-end)
                 (psyc-tutor--reference-key 'psyc-modal-goto-first-nonblank))
                "line and buffer edges")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-backward-sexp)
                 (psyc-tutor--reference-key 'psyc-modal-forward-sexp))
                "previous / next sexp")))
        (psyc-tutor--insert-reference-section
         "Select + Edit"
         (list
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-enter-select)
                 (psyc-tutor--reference-key 'psyc-modal-collapse)
                 (psyc-tutor--reference-key 'psyc-modal-select-all))
                "extend selection / collapse / select buffer")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-select-line)
                 (psyc-tutor--reference-key 'psyc-modal-select-line-above)
                 (psyc-tutor--reference-key 'psyc-modal-join-lines))
                "select line / line above / join lines")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-delete)
                 (psyc-tutor--reference-key 'psyc-modal-change)
                 (psyc-tutor--reference-key 'psyc-modal-yank))
                "delete / change / yank")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-paste-after)
                 (psyc-tutor--reference-key 'psyc-modal-paste-before)
                 (psyc-tutor--reference-key 'psyc-modal-replace-paste))
                "paste after / before / replace with yank")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-replace-char)
                 (psyc-tutor--reference-key 'psyc-modal-toggle-case)
                 (psyc-tutor--reference-key 'repeat))
                "replace char / toggle case / repeat last edit")))
        (psyc-tutor--insert-reference-section
         "Insert"
         (list
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-insert-before)
                 (psyc-tutor--reference-key 'psyc-modal-insert-after))
                "insert before / after point")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-insert-bol)
                 (psyc-tutor--reference-key 'psyc-modal-insert-eol))
                "insert at first non-blank / end of line")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-open-below)
                 (psyc-tutor--reference-key 'psyc-modal-open-above))
                "open a line below / above")
          (cons "<escape>" "return to normal state")))
        (psyc-tutor--insert-reference-section
         "Text Objects + Structure"
         (list
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "w")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-around "w"))
                "inside / around word")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "(")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-around "(")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "[")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-around "["))
                "inside / around parens and brackets")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "\"")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-around "\"")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "f")
                 (psyc-tutor--reference-prefix 'psyc-modal-select-around "f"))
                "inside / around quotes and functions")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-prefix 'psyc-modal-surround-add "(")
                 (psyc-tutor--reference-prefix 'psyc-modal-surround-delete "(")
                 (psyc-tutor--reference-prefix 'psyc-modal-surround-replace "( [")
                 (psyc-tutor--reference-prefix 'psyc-modal-wrap "("))
                "surround / delete surround / replace surround / wrap")
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-key 'psyc-modal-slurp-forward)
                 (psyc-tutor--reference-key 'psyc-modal-barf-forward)
                 (psyc-tutor--reference-key 'psyc-modal-splice)
                 (psyc-tutor--reference-key 'psyc-modal-raise))
                "slurp / barf / splice / raise")))
        (psyc-tutor--insert-reference-section
         "Practice"
         (list
          (cons (psyc-tutor--reference-alt
                 (psyc-tutor--reference-seq
                  (psyc-tutor--reference-key 'psyc-modal-word-next)
                  (psyc-tutor--reference-key 'psyc-modal-delete))
                 (psyc-tutor--reference-seq
                  (psyc-tutor--reference-key 'psyc-modal-select-line)
                  (psyc-tutor--reference-key 'psyc-modal-delete))
                 (psyc-tutor--reference-seq
                  (psyc-tutor--reference-key 'psyc-modal-select-line)
                  (psyc-tutor--reference-key 'psyc-modal-yank)))
                "delete word / delete line / yank line")
          (cons (psyc-tutor--reference-seq
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "w")
                 (psyc-tutor--reference-key 'psyc-modal-change))
                "change inside word")
          (cons (psyc-tutor--reference-seq
                 (psyc-tutor--reference-prefix 'psyc-modal-select-inside "(")
                 (psyc-tutor--reference-key 'psyc-modal-delete))
                "delete inside parens")
          (cons (psyc-tutor--reference-seq
                 (psyc-tutor--reference-key 'psyc-modal-select-all)
                 (psyc-tutor--reference-prefix 'psyc-modal-surround-add "("))
                "surround the whole buffer")
          (cons (psyc-tutor--reference-alt "??" "? t" "? k" "? m")
                "this reference / start tutor / modal keys / major-mode keys")))
        (insert "In this buffer: "
                (propertize "q" 'face 'help-key-binding)
                " quits, "
                (propertize "t" 'face 'help-key-binding)
                " starts the tutor, "
                (propertize "g" 'face 'help-key-binding)
                " refreshes the reference.\n")
        (goto-char (point-min))))
    (pop-to-buffer buf)))

(defun psyc-tutor (&optional difficulty)
  "Start the psyc-modal interactive tutor.
With prefix arg DIFFICULTY (1-5), set the starting level."
  (interactive "p")
  (let* ((diff (max 1 (min 5 (or difficulty 1))))
         (challenges (vconcat (psyc-tutor--shuffle (psyc-tutor--all-challenges))))
         (session (psyc-tutor-session--create
                   :challenges challenges
                   :current-idx 0
                   :difficulty diff
                   :show-hints-p (<= diff 2)
                   :stats (make-hash-table :test 'eql)
                   :start-time (float-time)
                   :window-config (current-window-configuration))))
    ;; Set up windows
    (psyc-tutor--setup-windows)
    ;; Initialize edit buffer
    (with-current-buffer (get-buffer psyc-tutor--edit-buf-name)
      (psyc-tutor-mode)
      (setq psyc-tutor--session session))
    ;; Select first eligible challenge
    (let ((first-idx (psyc-tutor--select-next session)))
      (when first-idx
        (setf (psyc-tutor-session-current-idx session) first-idx)
        (psyc-tutor--load-challenge session)))))

(defun psyc-tutor-skip ()
  "Skip the current challenge."
  (interactive)
  (when-let ((session psyc-tutor--session))
    ;; Record attempt without success (breaks streak)
    (let* ((idx (psyc-tutor-session-current-idx session))
           (stats-table (psyc-tutor-session-stats session))
           (stats (or (gethash idx stats-table)
                      (psyc-tutor-stats--create))))
      (cl-incf (psyc-tutor-stats-attempts stats))
      (setf (psyc-tutor-stats-streak stats) 0)
      (puthash idx stats stats-table))
    (psyc-tutor--advance session)))

(defun psyc-tutor-retry ()
  "Retry the current challenge."
  (interactive)
  (when-let ((session psyc-tutor--session))
    (psyc-tutor--load-challenge session)))

(defun psyc-tutor-quit ()
  "Quit the tutor and restore window layout."
  (interactive)
  (when-let ((session psyc-tutor--session))
    ;; Cancel timer
    (when (psyc-tutor-session-hint-timer session)
      (cancel-timer (psyc-tutor-session-hint-timer session)))
    ;; Restore windows
    (when (psyc-tutor-session-window-config session)
      (set-window-configuration (psyc-tutor-session-window-config session))))
  ;; Kill buffers
  (when-let ((buf (get-buffer psyc-tutor--edit-buf-name)))
    (kill-buffer buf))
  (when-let ((buf (get-buffer psyc-tutor--goal-buf-name)))
    (kill-buffer buf)))

(defun psyc-tutor-increase-difficulty ()
  "Increase the difficulty level."
  (interactive)
  (when-let ((session psyc-tutor--session))
    (let ((new-diff (min 5 (1+ (psyc-tutor-session-difficulty session)))))
      (setf (psyc-tutor-session-difficulty session) new-diff)
      (message "Difficulty: %d — %s" new-diff
               (psyc-tutor--diff-config new-diff :label))
      (psyc-tutor--advance session))))

(defun psyc-tutor-decrease-difficulty ()
  "Decrease the difficulty level."
  (interactive)
  (when-let ((session psyc-tutor--session))
    (let ((new-diff (max 1 (1- (psyc-tutor-session-difficulty session)))))
      (setf (psyc-tutor-session-difficulty session) new-diff)
      (message "Difficulty: %d — %s" new-diff
               (psyc-tutor--diff-config new-diff :label))
      (psyc-tutor--advance session))))

(defun psyc-tutor-show-stats ()
  "Show session statistics."
  (interactive)
  (when-let ((session psyc-tutor--session))
    (let ((total-attempts 0)
          (total-successes 0)
          (mastered 0))
      (maphash (lambda (_idx stats)
                 (cl-incf total-attempts (psyc-tutor-stats-attempts stats))
                 (cl-incf total-successes (psyc-tutor-stats-successes stats))
                 (when (psyc-tutor--mastered-p stats)
                   (cl-incf mastered)))
               (psyc-tutor-session-stats session))
      (message "Level %d | Completed: %d | Success rate: %d%% | Mastered: %d/%d"
               (psyc-tutor-session-difficulty session)
               (psyc-tutor-session-completed session)
               (if (> total-attempts 0)
                   (/ (* 100 total-successes) total-attempts) 0)
               mastered
               (length (psyc-tutor-session-challenges session))))))

(provide 'psyc-tutor)
;;; psyc-tutor.el ends here
