;;; test-psyc-modal.el --- Tests for psyc-modal -*- lexical-binding: t -*-

;;; Commentary:
;; Run: emacs --batch -L config/lisp/core -L config/lisp/editor \
;;              -l ert -l psyc-modal -l config/test/test-psyc-modal.el \
;;              -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'psyc-modal)

;;;; --- Test helpers ---

(defmacro with-modal-buffer (initial &rest body)
  "Create temp buffer with INITIAL text, activate modal, run BODY.
Point is at position 1 unless `|' marker is present in INITIAL."
  (declare (indent 1))
  `(with-temp-buffer
     (transient-mark-mode 1)
     (let* ((text (replace-regexp-in-string "|" "" ,initial))
            (pos (or (string-match "|" ,initial) 0)))
       (insert text)
       (goto-char (1+ pos))
       (psyc-modal-mode 1)
       (setq psyc-modal--state 'normal
             psyc-modal--normal-p t
             psyc-modal--insert-p nil)
       ,@body)))

(defun modal-buf-string ()
  "Return buffer string."
  (buffer-substring-no-properties (point-min) (point-max)))

(defun modal-selection ()
  "Return selected text or nil."
  (when (region-active-p)
    (buffer-substring-no-properties (region-beginning) (region-end))))

;;;; --- State transitions ---

(ert-deftest modal-test-enter-normal ()
  (with-modal-buffer "hello"
    (psyc-modal-enter-normal)
    (should (eq psyc-modal--state 'normal))
    (should psyc-modal--normal-p)
    (should-not psyc-modal--insert-p)
    (should (eq cursor-type 'box))))

(ert-deftest modal-test-enter-insert ()
  (with-modal-buffer "hello"
    (psyc-modal-enter-insert)
    (should (eq psyc-modal--state 'insert))
    (should-not psyc-modal--normal-p)
    (should psyc-modal--insert-p)
    (should (equal cursor-type '(bar . 2)))))

(ert-deftest modal-test-enter-select ()
  (with-modal-buffer "hello"
    (psyc-modal-enter-select)
    (should (eq psyc-modal--state 'select))
    (should (eq cursor-type 'hollow))
    ;; Toggle back
    (psyc-modal-enter-select)
    (should (eq psyc-modal--state 'normal))))

(ert-deftest modal-test-insert-backs-up-char ()
  "Entering normal from insert should move back one char (like helix)."
  (with-modal-buffer "hello"
    (goto-char 4) ; on 'l'
    (psyc-modal-enter-insert)
    (psyc-modal-enter-normal)
    (should (= (point) 3))))

(ert-deftest modal-test-insert-no-backup-at-bol ()
  "Should not back up past beginning of line."
  (with-modal-buffer "hello"
    (goto-char 1)
    (psyc-modal-enter-insert)
    (psyc-modal-enter-normal)
    (should (= (point) 1))))

;;;; --- Basic movements ---

(ert-deftest modal-test-hjkl ()
  (with-modal-buffer "ab\ncd"
    (goto-char 1)
    (psyc-modal-right)
    (should (= (point) 2))
    (psyc-modal-left)
    (should (= (point) 1))
    (psyc-modal-down)
    (should (= (point) 4))
    (psyc-modal-up)
    (should (= (point) 1))))

(ert-deftest modal-test-movement-creates-selection ()
  "Normal mode movements should create a fresh selection."
  (with-modal-buffer "hello world"
    (goto-char 1)
    (psyc-modal-right)
    (should (region-active-p))
    (should (= (mark) 1))
    (should (= (point) 2))))

(ert-deftest modal-test-select-mode-extends ()
  "Select mode should extend, not replace selection."
  (with-modal-buffer "hello"
    (goto-char 1)
    (psyc-modal-enter-select)
    (psyc-modal-right)
    (psyc-modal-right)
    (psyc-modal-right)
    (should (= (mark) 1))
    (should (= (point) 4))
    (should (equal (modal-selection) "hel"))))

;;;; --- Word movements ---

(ert-deftest modal-test-word-next ()
  "w should move to start of next word."
  (with-modal-buffer "hello world"
    (goto-char 1)
    (psyc-modal-word-next)
    (should (= (point) 7)))) ; 'w' of "world"

(ert-deftest modal-test-word-next-punctuation ()
  "w should treat punctuation as separate word class."
  (with-modal-buffer "hello.world"
    (goto-char 1)
    (psyc-modal-word-next)
    (should (= (point) 6)))) ; '.'

(ert-deftest modal-test-word-back ()
  "b should move to start of previous word."
  (with-modal-buffer "hello world"
    (goto-char 7)
    (psyc-modal-word-back)
    (should (= (point) 1))))

(ert-deftest modal-test-word-end ()
  "e should move to end of word."
  (with-modal-buffer "hello world"
    (goto-char 1)
    (psyc-modal-word-end)
    (should (= (point) 5)))) ; 'o' of "hello"

(ert-deftest modal-test-WORD-next ()
  "W should move to start of next WORD (whitespace-delimited)."
  (with-modal-buffer "hello.world foo"
    (goto-char 1)
    (psyc-modal-WORD-next)
    (should (= (point) 13)))) ; 'f' of "foo"

;;;; --- Find / till ---

(ert-deftest modal-test-find-forward ()
  (with-modal-buffer "hello world"
    (goto-char 1)
    (cl-letf (((symbol-function 'read-char) (lambda (&rest _) ?o)))
      (psyc-modal-find-forward))
    (should (= (point) 5)))) ; 'o' in hello

(ert-deftest modal-test-till-forward ()
  (with-modal-buffer "hello world"
    (goto-char 1)
    (cl-letf (((symbol-function 'read-char) (lambda (&rest _) ?o)))
      (psyc-modal-till-forward))
    (should (= (point) 4)))) ; before 'o'

(ert-deftest modal-test-find-backward ()
  (with-modal-buffer "hello world"
    (goto-char 11)
    (cl-letf (((symbol-function 'read-char) (lambda (&rest _) ?l)))
      (psyc-modal-find-backward))
    (should (= (point) 10)))) ; 'l' in world

;;;; --- Line operations ---

(ert-deftest modal-test-select-line ()
  (with-modal-buffer "line one\nline two\n"
    (goto-char 1)
    (psyc-modal-select-line)
    (should (equal (modal-selection) "line one\n"))))

(ert-deftest modal-test-select-line-extend ()
  "Repeating x should extend line selection."
  (with-modal-buffer "one\ntwo\nthree\n"
    (goto-char 1)
    (let ((last-command nil))
      (psyc-modal-select-line)
      (setq last-command 'psyc-modal-select-line)
      (psyc-modal-select-line)
      (should (equal (modal-selection) "one\ntwo\n")))))

(ert-deftest modal-test-join-lines ()
  (with-modal-buffer "hello\nworld"
    (goto-char 1)
    (psyc-modal-join-lines)
    (should (equal (modal-buf-string) "hello world"))))

;;;; --- Actions ---

(ert-deftest modal-test-delete-selection ()
  (with-modal-buffer "hello world"
    (goto-char 1)
    (set-mark 6)
    (psyc-modal-delete)
    (should (equal (modal-buf-string) " world"))))

(ert-deftest modal-test-delete-no-selection ()
  "d without selection should delete char at point."
  (with-modal-buffer "hello"
    (goto-char 1)
    (psyc-modal-delete)
    (should (equal (modal-buf-string) "ello"))))

(ert-deftest modal-test-change ()
  (with-modal-buffer "hello world"
    (goto-char 1)
    (set-mark 6)
    (psyc-modal-change)
    (should (equal (modal-buf-string) " world"))
    (should (eq psyc-modal--state 'insert))))

(ert-deftest modal-test-yank-copy ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (set-mark 6)
    (psyc-modal-yank)
    (should (equal (car kill-ring) "hello"))
    (should-not (region-active-p))))

(ert-deftest modal-test-paste-after ()
  (with-modal-buffer "ab"
    (kill-new "XY")
    (goto-char 1)
    (deactivate-mark)
    (psyc-modal-paste-after)
    (should (string-match-p "XY" (modal-buf-string)))))

(ert-deftest modal-test-replace-char ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (cl-letf (((symbol-function 'read-char) (lambda (&rest _) ?X)))
      (psyc-modal-replace-char))
    (should (equal (modal-buf-string) "Xello"))))

(ert-deftest modal-test-toggle-case ()
  (with-modal-buffer "Hello"
    (goto-char 1)
    (psyc-modal-toggle-case)
    (should (equal (modal-buf-string) "hello"))))

(ert-deftest modal-test-indent ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (let ((tab-width 2)
          (indent-tabs-mode nil))
      (psyc-modal-indent)
      (should (string-match-p "^ +hello" (modal-buf-string))))))

;;;; --- Insert entry ---

(ert-deftest modal-test-insert-before ()
  (with-modal-buffer "hello"
    (goto-char 3)
    (set-mark 5)
    (psyc-modal-insert-before)
    (should (= (point) 3))
    (should (eq psyc-modal--state 'insert))))

(ert-deftest modal-test-insert-after ()
  (with-modal-buffer "hello"
    (goto-char 3)
    (set-mark 5)
    (psyc-modal-insert-after)
    (should (= (point) 5))
    (should (eq psyc-modal--state 'insert))))

(ert-deftest modal-test-open-below ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (psyc-modal-open-below)
    (should (eq psyc-modal--state 'insert))
    (should (= (line-number-at-pos) 2))))

(ert-deftest modal-test-open-above ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (psyc-modal-open-above)
    (should (eq psyc-modal--state 'insert))
    (should (= (line-number-at-pos) 1))))

;;;; --- Search ---

(ert-deftest modal-test-search-next ()
  (with-modal-buffer "foo bar foo baz foo"
    (setq psyc-modal--last-search '("foo" . nil))
    (goto-char 1)
    (psyc-modal-search-next)
    (should (= (match-beginning 0) 9))
    (should (region-active-p))))

(ert-deftest modal-test-search-next-wraps ()
  (with-modal-buffer "foo bar"
    (setq psyc-modal--last-search '("foo" . nil))
    (goto-char 5)
    (psyc-modal-search-next)
    ;; Should wrap to beginning
    (should (= (match-beginning 0) 1))))

(ert-deftest modal-test-search-selection ()
  "* should search for word at point."
  (with-modal-buffer "hello world hello"
    (goto-char 1)
    (psyc-modal-search-selection)
    (should (equal (car psyc-modal--last-search)
                   (regexp-quote "hello")))))

(ert-deftest modal-test-select-regex ()
  (with-modal-buffer "foo bar baz"
    (goto-char 1)
    (push-mark (point-max) t t)
    (cl-letf (((symbol-function 'read-string) (lambda (&rest _) "bar")))
      (psyc-modal-select-regex))
    (should (equal (modal-selection) "bar"))))

;;;; --- Selection ---

(ert-deftest modal-test-collapse ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (set-mark 5)
    (psyc-modal-collapse)
    (should-not (region-active-p))))

(ert-deftest modal-test-select-all ()
  (with-modal-buffer "hello\nworld"
    (psyc-modal-select-all)
    (should (equal (modal-selection) "hello\nworld"))))

(ert-deftest modal-test-flip-selection ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (set-mark 5)
    (psyc-modal-flip-selection)
    (should (= (point) 5))
    (should (= (mark) 1))))

;;;; --- Text objects ---

(ert-deftest modal-test-select-inside-parens ()
  (with-modal-buffer "(hello world)"
    (goto-char 5)
    (psyc-modal--select-textobj ?\( nil)
    (should (equal (modal-selection) "hello world"))))

(ert-deftest modal-test-select-around-parens ()
  (with-modal-buffer "(hello world)"
    (goto-char 5)
    (psyc-modal--select-textobj ?\( t)
    (should (equal (modal-selection) "(hello world)"))))

(ert-deftest modal-test-select-inside-brackets ()
  (with-modal-buffer "[hello world]"
    (goto-char 5)
    (psyc-modal--select-textobj ?\[ nil)
    (should (equal (modal-selection) "hello world"))))

(ert-deftest modal-test-select-inside-braces ()
  (with-modal-buffer "{hello world}"
    (goto-char 5)
    (psyc-modal--select-textobj ?{ nil)
    (should (equal (modal-selection) "hello world"))))

(ert-deftest modal-test-select-inside-nested ()
  "Should find the CORRECT bracket type, not just nearest."
  (with-modal-buffer "[outer (inner) end]"
    (goto-char 10) ; inside 'inner'
    (psyc-modal--select-textobj ?\( nil)
    (should (equal (modal-selection) "inner"))))

(ert-deftest modal-test-select-inside-quotes ()
  (with-modal-buffer "say \"hello world\" ok"
    (goto-char 8)
    (psyc-modal--select-textobj ?\" nil)
    (should (equal (modal-selection) "hello world"))))

(ert-deftest modal-test-select-inside-word ()
  (with-modal-buffer "hello world"
    (goto-char 3)
    (psyc-modal--select-textobj ?w nil)
    (should (equal (modal-selection) "hello"))))

(ert-deftest modal-test-select-nearest-pair ()
  (with-modal-buffer "(hello [world])"
    (goto-char 10)
    (psyc-modal--select-textobj ?m nil)
    (should (equal (modal-selection) "world"))))

;;;; --- Surround ---

(ert-deftest modal-test-surround-add ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (set-mark 6) ; select "hello"
    (cl-letf (((symbol-function 'read-char) (lambda (&rest _) ?\()))
      (psyc-modal-surround-add))
    (should (equal (modal-buf-string) "(hello)"))))

(ert-deftest modal-test-surround-delete ()
  (with-modal-buffer "(hello)"
    (goto-char 4)
    (cl-letf (((symbol-function 'read-char) (lambda (&rest _) ?\()))
      (psyc-modal-surround-delete))
    (should (equal (modal-buf-string) "hello"))))

(ert-deftest modal-test-surround-replace ()
  (with-modal-buffer "(hello)"
    (goto-char 4)
    (let ((chars '(?\( ?\[)))
      (cl-letf (((symbol-function 'read-char)
                 (lambda (&rest _) (pop chars))))
        (psyc-modal-surround-replace)))
    (should (equal (modal-buf-string) "[hello]"))))

;;;; --- Structural editing ---

(ert-deftest modal-test-slurp-forward ()
  (with-modal-buffer "(a) b"
    (goto-char 2)
    (psyc-modal-slurp-forward)
    (should (equal (modal-buf-string) "(a b)"))))

(ert-deftest modal-test-barf-forward ()
  (with-modal-buffer "(a b)"
    (goto-char 2)
    (psyc-modal-barf-forward)
    (should (equal (modal-buf-string) "(a) b"))))

(ert-deftest modal-test-slurp-backward ()
  (with-modal-buffer "a (b)"
    (goto-char 4)
    (psyc-modal-slurp-backward)
    (should (equal (modal-buf-string) "(a b)"))))

(ert-deftest modal-test-barf-backward ()
  (with-modal-buffer "(a b)"
    (goto-char 4)
    (psyc-modal-barf-backward)
    (should (equal (modal-buf-string) "a (b)"))))

(ert-deftest modal-test-splice ()
  (with-modal-buffer "(hello)"
    (goto-char 4)
    (psyc-modal-splice)
    (should (equal (modal-buf-string) "hello"))))

(ert-deftest modal-test-raise ()
  "Raise should replace parent sexp with sexp at point."
  (with-modal-buffer "(a b)"
    (goto-char 4) ; on 'b'
    (forward-sexp) ; after 'b'
    (psyc-modal-raise)
    (should (equal (modal-buf-string) "b"))))

(ert-deftest modal-test-transpose-sexp ()
  (with-modal-buffer "(a b)"
    (goto-char 2) ; on 'a'
    (forward-sexp) ; after 'a'
    (psyc-modal-transpose-sexp)
    (should (equal (modal-buf-string) "(b a)"))))

(ert-deftest modal-test-wrap ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (cl-letf (((symbol-function 'read-char) (lambda (&rest _) ?\()))
      (psyc-modal-wrap))
    (should (equal (modal-buf-string) "(hello)"))))

;;;; --- Insert mode balanced delete ---

(ert-deftest modal-test-balanced-delete-pair ()
  "Deleting between () should remove both."
  (with-modal-buffer "()"
    (goto-char 2) ; between ( and )
    (psyc-modal-enter-insert)
    (psyc-modal-insert-backward-delete)
    (should (equal (modal-buf-string) ""))))

;;;; --- Goto mode ---

(ert-deftest modal-test-goto-file-start ()
  (with-modal-buffer "hello\nworld"
    (goto-char (point-max))
    (psyc-modal-goto-file-start)
    (should (= (point) (point-min)))))

(ert-deftest modal-test-goto-file-end ()
  (with-modal-buffer "hello\nworld"
    (goto-char 1)
    (psyc-modal-goto-file-end)
    (should (= (point) (point-max)))))

(ert-deftest modal-test-goto-line-start ()
  (with-modal-buffer "  hello"
    (goto-char 5)
    (psyc-modal-goto-line-start)
    (should (= (point) 1))))

(ert-deftest modal-test-goto-first-nonblank ()
  (with-modal-buffer "  hello"
    (goto-char 6)
    (psyc-modal-goto-first-nonblank)
    (should (= (point) 3))))

;;;; --- God mode ---

(ert-deftest modal-test-god-modify ()
  "God mode should correctly apply control modifier."
  (let ((event (psyc-modal--god-modify ?a 'ctrl)))
    (should (equal event ?\C-a)))
  (let ((event (psyc-modal--god-modify ?x 'meta)))
    (should (equal event (event-convert-list '(meta ?x)))))
  (let ((event (psyc-modal--god-modify ?x 'ctrl-meta)))
    (should (equal event (event-convert-list '(control meta ?x))))))

;;;; --- Increment / decrement ---

(ert-deftest modal-test-increment ()
  (with-modal-buffer "count: 42"
    (goto-char 9) ; on '4'
    (increment-number-at-point)
    (should (equal (modal-buf-string) "count: 43"))))

(ert-deftest modal-test-decrement ()
  (with-modal-buffer "count: 42"
    (goto-char 9)
    (decrement-number-at-point)
    (should (equal (modal-buf-string) "count: 41"))))

;;;; --- Count prefix ---

(ert-deftest modal-test-count-movement ()
  "3l should move right 3 chars."
  (with-modal-buffer "hello world"
    (goto-char 1)
    (let ((current-prefix-arg 3))
      (psyc-modal-right))
    (should (= (point) 4))))

(ert-deftest modal-test-count-word ()
  "2w should move forward 2 words."
  (with-modal-buffer "one two three"
    (goto-char 1)
    (let ((current-prefix-arg 2))
      (psyc-modal-word-next))
    (should (= (point) 9)))) ; 't' of "three"

;;;; --- Sexp movements ---

(ert-deftest modal-test-forward-sexp ()
  (with-modal-buffer "(foo) (bar)"
    (goto-char 1)
    (psyc-modal-forward-sexp)
    (should (= (point) 6)))) ; after (foo)

(ert-deftest modal-test-backward-sexp ()
  (with-modal-buffer "(foo) (bar)"
    (goto-char 12) ; after (bar)
    (psyc-modal-backward-sexp)
    (should (= (point) 7)))) ; before (bar)

;;;; --- Char pair helper ---

(ert-deftest modal-test-char-pair ()
  (should (equal (psyc-modal--char-pair ?\() '("(" . ")")))
  (should (equal (psyc-modal--char-pair ?\)) '("(" . ")")))
  (should (equal (psyc-modal--char-pair ?{) '("{" . "}")))
  (should (equal (psyc-modal--char-pair ?<) '("<" . ">")))
  (should (equal (psyc-modal--char-pair ?*) '("*" . "*"))))

;;;; --- Alt-action variants ---

(ert-deftest modal-test-delete-no-yank ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (set-mark 6)
    (let ((kill-ring nil))
      (psyc-modal-delete-no-yank)
      (should (equal (modal-buf-string) ""))
      (should-not kill-ring))))

(ert-deftest modal-test-change-no-yank ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (set-mark 6)
    (let ((kill-ring nil))
      (psyc-modal-change-no-yank)
      (should (equal (modal-buf-string) ""))
      (should (eq psyc-modal--state 'insert))
      (should-not kill-ring))))

(ert-deftest modal-test-pipe-shell ()
  (with-modal-buffer "hello"
    (goto-char 1)
    (set-mark 6)
    (cl-letf (((symbol-function 'read-string) (lambda (&rest _) "tr a-z A-Z")))
      (psyc-modal-pipe-shell))
    (should (equal (modal-buf-string) "HELLO"))))

(ert-deftest modal-test-keep-matching ()
  (with-modal-buffer "apple\nbanana\napricot\n"
    (goto-char 1)
    (set-mark (point-max))
    (cl-letf (((symbol-function 'read-string) (lambda (&rest _) "^ap")))
      (psyc-modal-keep-matching))
    (should (string-match-p "apple" (modal-buf-string)))
    (should (string-match-p "apricot" (modal-buf-string)))
    (should-not (string-match-p "banana" (modal-buf-string)))))

(ert-deftest modal-test-ensure-forward ()
  "Alt-: should flip selection so mark < point."
  (with-modal-buffer "hello"
    (goto-char 1)
    (set-mark 5)
    (exchange-point-and-mark) ; now point=5, mark=1 → swap so mark > point
    ;; Actually: point=1, mark=5 after exchange. Let me set it up reversed:
    (goto-char 5)
    (set-mark 1)
    ;; Now mark=1, point=5 → already forward. Let me reverse:
    (goto-char 1)
    (set-mark 5)
    ;; mark=5 > point=1 → backward selection
    (psyc-modal-ensure-forward)
    ;; After: mark < point
    (should (<= (mark) (point)))))

(ert-deftest modal-test-shrink-to-line ()
  (with-modal-buffer "  hello  \n  world  \n"
    (goto-char 1)
    (set-mark (point-max))
    (psyc-modal-shrink-to-line)
    ;; Selection should start at "hello" not "  hello"
    (should (region-active-p))
    (should (= (region-beginning) 3))))

;;;; --- Search selection ---

(ert-deftest modal-test-search-selection-with-region ()
  "* with active region should use region text."
  (with-modal-buffer "foo bar foo"
    (goto-char 1)
    (set-mark 4)  ; select "foo"
    (psyc-modal-search-selection)
    (should (equal (car psyc-modal--last-search)
                   (regexp-quote "foo")))))

;;;; --- Structural editing: wrap with selection ---

(ert-deftest modal-test-wrap-selection ()
  (with-modal-buffer "hello world"
    (goto-char 1)
    (set-mark 6)
    (cl-letf (((symbol-function 'read-char) (lambda (&rest _) ?\[)))
      (psyc-modal-wrap))
    (should (equal (modal-buf-string) "[hello] world"))))

;;;; --- Text objects: function (fallback) ---

(ert-deftest modal-test-select-inside-function ()
  (with-modal-buffer "(defun foo ()\n  (bar))\n"
    (emacs-lisp-mode)
    (goto-char 10)
    (psyc-modal-select-inside-function)
    (should (region-active-p))
    (should (string-match-p "defun" (modal-selection)))))

;;;; --- For-each-line ---

(ert-deftest modal-test-for-each-line-basic ()
  "For-each-line should run a command on every line in selection."
  (with-modal-buffer "  hello\n  world\n  there"
    (goto-char 1)
    (set-mark (point-max))
    (cl-letf (((symbol-function 'completing-read)
               (lambda (&rest _) "delete-trailing-whitespace")))
      (psyc-modal-for-each-line))
    ;; Should not error, and buffer should remain intact (no trailing ws to delete here)
    (should (equal (modal-buf-string) "  hello\n  world\n  there"))))

(ert-deftest modal-test-for-each-line-upcase ()
  "For-each-line with upcase-region should upcase each line."
  (with-modal-buffer "aaa\nbbb\nccc"
    (goto-char 1)
    (set-mark (point-max))
    (cl-letf (((symbol-function 'completing-read)
               (lambda (&rest _) "upcase-region")))
      (psyc-modal-for-each-line))
    (should (equal (modal-buf-string) "AAA\nBBB\nCCC"))))

(ert-deftest modal-test-for-each-line-single-line ()
  "For-each-line on a single line."
  (with-modal-buffer "hello"
    (goto-char 1)
    (set-mark (point-max))
    (cl-letf (((symbol-function 'completing-read)
               (lambda (&rest _) "upcase-region")))
      (psyc-modal-for-each-line))
    (should (equal (modal-buf-string) "HELLO"))))

(ert-deftest modal-test-for-each-line-no-region ()
  "For-each-line without selection should error."
  (with-modal-buffer "hello"
    (deactivate-mark)
    (should-error (psyc-modal-for-each-line) :type 'user-error)))

;;;; --- Split ring ---

(ert-deftest modal-test-split-selection-basic ()
  "Split selection should populate the split ring."
  (with-modal-buffer "alpha\nbeta\ngamma"
    (goto-char 1)
    (set-mark (point-max))
    (psyc-modal-split-selection)
    (should (equal psyc-modal--split-ring '("alpha" "beta" "gamma")))))

(ert-deftest modal-test-paste-split-fifo ()
  "Paste-split should consume pieces FIFO."
  (with-modal-buffer ""
    (setq psyc-modal--split-ring '("one" "two" "three"))
    (psyc-modal-paste-split)
    (should (equal (modal-buf-string) "one"))
    (should (equal psyc-modal--split-ring '("two" "three")))
    (psyc-modal-paste-split)
    (should (equal (modal-buf-string) "onetwo"))
    (should (equal psyc-modal--split-ring '("three")))
    (psyc-modal-paste-split)
    (should (equal (modal-buf-string) "onetwothree"))
    (should (null psyc-modal--split-ring))))

(ert-deftest modal-test-paste-split-empty ()
  "Paste-split with exhausted ring should error."
  (with-modal-buffer ""
    (setq psyc-modal--split-ring nil)
    (should-error (psyc-modal-paste-split) :type 'user-error)))

(ert-deftest modal-test-split-selection-custom-separator ()
  "Split with custom separator via prefix arg."
  (with-modal-buffer "a,b,c"
    (goto-char 1)
    (set-mark (point-max))
    (let ((current-prefix-arg '(4)))
      (cl-letf (((symbol-function 'read-string)
                 (lambda (&rest _) ",")))
        (psyc-modal-split-selection)))
    (should (equal psyc-modal--split-ring '("a" "b" "c")))))

(ert-deftest modal-test-split-empty-pieces ()
  "Split with consecutive separators produces empty strings."
  (with-modal-buffer "a\n\nb"
    (goto-char 1)
    (set-mark (point-max))
    (psyc-modal-split-selection)
    (should (equal psyc-modal--split-ring '("a" "" "b")))))

;;; test-psyc-modal.el ends here
