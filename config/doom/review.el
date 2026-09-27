;;; $DOOMDIR/review.el -*- lexical-binding: t; -*-

;; Review: annotate code where you read it and queue the notes for whatever
;; coding agent you are running next door. Port of nvim's after/plugin/review.lua.
;;
;; Stateless: every comment lives in the `rvw' queue, keyed by workspace; this
;; only draws what the command reports and acts on it by id. A comment added
;; here, from a shell, or from nvim shows up in all of them.
;;
;; Workflow:
;;   1. Select a region, press RET (or SPC r a) -> an input buffer opens.
;;   2. Type the comment. C-c C-c / C-s queues it (`rvw add') and marks the
;;      line; C-c C-k cancels. ESC only leaves insert state.
;;   3. The agent runs `rvw pull'. Pulled comments lose their mark on the next
;;      refresh (buffer switch, save, focus, or SPC r r).

(require 'json)

(defvar gs/review-command (or (getenv "RVW_CMD") "rvw")
  "The queue command. $RVW_CMD overrides it (e.g. a wrapper that passes --db).")

(defconst gs/review-decisions '("comment" "approve" "request-changes"))

(defface gs/review-sign '((t :inherit success))
  "Face of the mark on a line holding a queued review comment.")

(when (fboundp 'define-fringe-bitmap)
  (define-fringe-bitmap 'gs/review-sign
    [#b01111110 #b11111111 #b11111111 #b11111111 #b11111111 #b01111110 #b00110000 #b00100000]))

;;; Running the command

(defun gs/review--executable ()
  (or (executable-find gs/review-command)
      (user-error "Review: `%s' is not on $PATH -- run `make install' in ~/Projects/rvw"
                  gs/review-command)))

(defun gs/review--run (args &optional stdin-buffer)
  "Run the queue command with ARGS and return its stdout.
The whole of STDIN-BUFFER, if given, is piped in. Signals the command's
stderr on failure. Synchronous: only for commands a keystroke waits on."
  (gs/review--executable)
  (let ((stderr (make-temp-file "rvw-stderr"))
        (source (or stdin-buffer (current-buffer))))
    (unwind-protect
        (with-temp-buffer
          (let* ((out (current-buffer))
                 (status (with-current-buffer source
                           (save-restriction
                             (widen)
                             (apply #'call-process-region
                                    (if stdin-buffer (point-min) "")
                                    (if stdin-buffer (point-max) nil)
                                    gs/review-command nil (list out stderr) nil args)))))
            (unless (eq status 0)
              (let ((err (string-trim (with-temp-buffer
                                        (insert-file-contents stderr)
                                        (buffer-string)))))
                (user-error "Review: %s" (if (string-empty-p err) "command failed" err))))
            (buffer-string)))
      (delete-file stderr))))

(defun gs/review--decode (out)
  "Comments (alists) from the JSON OUT of `rvw list --format json'."
  (when (and out (not (string-empty-p out)))
    (condition-case nil
        (append (alist-get 'reviews (json-parse-string out :object-type 'alist
                                                        :array-type 'list
                                                        :null-object nil))
                nil)
      (json-parse-error nil))))

(defun gs/review--list-args (&optional file)
  "Reads are --all-lanes: the editor is the whole-tree view, so a lane pin must
never hide a note on the file you are looking at. It passes no --lane, so
comments added here are unlaned."
  (append '("list" "--format" "json" "--all-lanes")
          (when file (list "--file" file))))

(defun gs/review--query (&optional file)
  (gs/review--decode (gs/review--run (gs/review--list-args file))))

(defun gs/review--range (item)
  (let ((start (alist-get 'start_line item)) (end (alist-get 'end_line item)))
    (if (= start end) (number-to-string start) (format "%d-%d" start end))))

(defun gs/review--label (item)
  (format "%s: %s:%s" (alist-get 'id item)
          (file-name-nondirectory (alist-get 'path item)) (gs/review--range item)))

;;; Signs

(defun gs/review--clear-signs ()
  (remove-overlays (point-min) (point-max) 'gs/review t))

(defun gs/review--sign-string (comment)
  (propertize " " 'display
              (if (display-graphic-p)
                  '(right-fringe gs/review-sign gs/review-sign)
                `((margin right-margin) ,(propertize "*" 'face 'gs/review-sign)))
              'help-echo comment))

(defun gs/review--draw (items)
  (save-restriction
    (widen)
    (gs/review--clear-signs)
    (unless (display-graphic-p)
      (setq-local right-margin-width (if items 1 0))
      (dolist (win (get-buffer-window-list nil nil t))
        (set-window-buffer win (current-buffer))))
    (let ((last (line-number-at-pos (point-max))))
      (dolist (item items)
        (save-excursion
          (goto-char (point-min))
          (forward-line (1- (min (alist-get 'start_line item) last)))
          (let ((ov (make-overlay (point) (point))))
            (overlay-put ov 'gs/review t)
            (overlay-put ov 'before-string
                         (gs/review--sign-string (alist-get 'comment item)))))))))

(defun gs/review-refresh (&optional buffer)
  "Redraw BUFFER's marks from the queue without blocking.
Marks are replaced only once the queue answers, so they never blink."
  (let ((buffer (or buffer (current-buffer))))
    (with-current-buffer buffer
      (when (and buffer-file-name (executable-find gs/review-command)
                 (file-directory-p default-directory)
                 (not (file-remote-p default-directory)))
        (let ((out (generate-new-buffer " *rvw-refresh*" t)))
          (make-process
           :name "rvw-refresh" :buffer out :noquery t
           :command (cons gs/review-command
                          (gs/review--list-args (expand-file-name buffer-file-name)))
           :stderr (make-pipe-process :name "rvw-refresh-stderr" :noquery t
                                      :buffer nil :filter #'ignore)
           :sentinel
           (lambda (proc _event)
             (unless (process-live-p proc)
               ;; a background redraw never interrupts with an error
               (when (and (eq (process-exit-status proc) 0) (buffer-live-p buffer))
                 (let ((items (gs/review--decode
                               (with-current-buffer out (buffer-string)))))
                   (with-current-buffer buffer (gs/review--draw items))))
               (kill-buffer out)))))))))

(defun gs/review-refresh-all ()
  "Redraw review marks in every file buffer (after an agent pulled, say)."
  (interactive)
  (dolist (buf (buffer-list))
    (when (buffer-file-name buf) (gs/review-refresh buf))))

;;; Input buffer

(defvar-local gs/review--on-save nil)
(defvar-local gs/review--window-config nil)

(defun gs/review--close (save)
  (let ((text (string-trim-right (buffer-string)))
        (on-save gs/review--on-save)
        (config gs/review--window-config))
    (kill-buffer)
    (when config (set-window-configuration config))
    (when save (funcall on-save text))))

(defun gs/review-input-save ()
  (interactive)
  (gs/review--close t))

(defun gs/review-input-cancel ()
  (interactive)
  (gs/review--close nil))

(defvar gs/review-input-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'gs/review-input-save)
    (define-key map (kbd "C-s") #'gs/review-input-save)
    (define-key map (kbd "C-c C-k") #'gs/review-input-cancel)
    map))

(define-minor-mode gs/review-input-mode
  "Minor mode of the review comment input buffer."
  :keymap gs/review-input-mode-map)

(defun gs/review--open-input (title on-save &optional initial)
  "Open an input buffer titled TITLE; ON-SAVE gets the text on C-c C-c.
The only ways out are save and cancel, so ESC never throws the text away."
  (let ((config (current-window-configuration))
        (buf (generate-new-buffer "*review-input*")))
    (pop-to-buffer buf '((display-buffer-below-selected)
                         (window-height . 8)))
    (if (fboundp 'markdown-mode) (markdown-mode) (text-mode))
    (gs/review-input-mode 1)
    (setq gs/review--on-save on-save
          gs/review--window-config config
          header-line-format (format " %s  (C-c C-c save · C-c C-k cancel)" title))
    (when initial (insert initial))
    (when (bound-and-true-p evil-local-mode)
      ;; evil keymaps shadow minor-mode maps; bind in the evil states too
      (dolist (state '(normal insert))
        (evil-local-set-key state (kbd "C-s") #'gs/review-input-save)
        (evil-local-set-key state (kbd "C-c C-c") #'gs/review-input-save)
        (evil-local-set-key state (kbd "C-c C-k") #'gs/review-input-cancel))
      (evil-insert-state))))

;;; Commands

(defun gs/review--filetype ()
  (string-remove-suffix "-ts" (string-remove-suffix "-mode" (symbol-name major-mode))))

(defun gs/review-add (beg end)
  "Queue a review comment on the region (or current line).
The buffer is piped in as the code snapshot, so an unsaved edit is captured
exactly as it reads on screen."
  (interactive (if (use-region-p)
                   (list (region-beginning) (region-end))
                 (list (point) (point))))
  (let* ((file (or buffer-file-name (user-error "Review: buffer has no file to reference")))
         (path (expand-file-name file))
         (source (current-buffer))
         (start (line-number-at-pos beg))
         (stop (line-number-at-pos (if (and (> end beg)
                                            (save-excursion (goto-char end) (bolp)))
                                       (1- end)
                                     end)))
         (range (if (= start stop) (number-to-string start) (format "%d-%d" start stop)))
         (filetype (gs/review--filetype)))
    (when (bound-and-true-p evil-local-mode)
      (when (evil-visual-state-p) (evil-exit-visual-state)))
    (deactivate-mark)
    (gs/review--open-input
     "Review"
     (lambda (text)
       (unless (string-blank-p text)
         (let ((out (with-current-buffer source
                      (gs/review--run
                       (append (list "add" "--file" path "--lines" range "--comment" text
                                     "--code-file" "-" "--format" "ids")
                               (unless (string-empty-p filetype)
                                 (list "--filetype" filetype)))
                       source))))
           (gs/review-refresh source)
           (message "Review queued %s: %s:%s" (string-trim out)
                    (file-name-nondirectory path) range)))))))

(defun gs/review--near-point ()
  "The queued comment nearest point in this buffer: a range holding point
wins, else the nearest by distance. The queue is asked fresh every time."
  (let ((line (line-number-at-pos))
        best best-dist)
    (when buffer-file-name
      (dolist (item (gs/review--query (expand-file-name buffer-file-name)))
        (let* ((start (alist-get 'start_line item))
               (end (alist-get 'end_line item))
               (dist (if (<= start line end) 0
                       (min (abs (- line start)) (abs (- line end))))))
          (when (or (null best-dist) (< dist best-dist))
            (setq best item best-dist dist)))))
    (or best (user-error "Review: no queued comment near point in this buffer"))))

(defun gs/review-withdraw ()
  "Withdraw the queued comment nearest point (`rvw reject' with a reason).
Nothing in rvw is deleted; the comment leaves the queue but stays on record."
  (interactive)
  (let* ((item (gs/review--near-point))
         (note (read-string (format "Withdraw %s, reason: " (gs/review--label item))
                            "withdrawn: ")))
    (gs/review--run (list "reject" (alist-get 'id item) "--note" note))
    (gs/review-refresh)
    (message "Review withdrew %s" (gs/review--label item))))

(defun gs/review-edit ()
  "Rewrite the text of the queued comment nearest point."
  (interactive)
  (let ((item (gs/review--near-point))
        (source (current-buffer)))
    (gs/review--open-input
     (format "Edit review %s" (alist-get 'id item))
     (lambda (text)
       (if (string-blank-p text)
           (message "Review: empty comment, left unchanged")
         (with-current-buffer source
           (gs/review--run (list "edit" (alist-get 'id item) "--comment" text)))
         (gs/review-refresh source)
         (message "Review updated %s" (gs/review--label item))))
     (alist-get 'comment item))))

(defun gs/review-list ()
  "List the workspace queue in a grep-mode buffer: RET or ]c / [c visit a
comment; from there, SPC r e / SPC r d act on the one at point."
  (interactive)
  (let ((items (gs/review--query))
        (dir default-directory))
    (unless items (user-error "Review: the queue is empty for this workspace"))
    (with-current-buffer (get-buffer-create "*review*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (setq default-directory dir)
        (insert "Review queue\n\n")
        (dolist (item items)
          (let ((tags (delq nil (list (when-let* ((a (alist-get 'author item))) (concat "@" a))
                                      (when-let* ((l (alist-get 'lane item))) (concat "#" l))))))
            (insert (format "%s:%d:%s. [%s] %s%s\n"
                            (alist-get 'path item) (alist-get 'start_line item)
                            (alist-get 'id item) (gs/review--range item)
                            (if tags (concat (string-join tags " ") " ") "")
                            (car (split-string (alist-get 'comment item) "\n")))))))
      (grep-mode)
      (goto-char (point-min))
      (pop-to-buffer (current-buffer)))))

(defun gs/review-submit (decision)
  "Submit a review with DECISION over this author's pending comments in the
current lane. The CLI owns selection; the editor supplies only the decision
and summary."
  (interactive (list (completing-read "Decision: " gs/review-decisions nil t)))
  (unless (member decision gs/review-decisions)
    (user-error "Review: decision must be comment, approve, or request-changes"))
  (let ((source (current-buffer)))
    (gs/review--open-input
     "Review summary"
     (lambda (summary)
       (unless (string-blank-p summary)
         (let ((out (with-current-buffer source
                      (gs/review--run (list "submit" "--decision" decision
                                            "--summary" summary "--format" "ids")))))
           (message "Review submitted %s" (string-trim out))))))))

;;; Refresh triggers: marks come from the queue, never from memory

(add-hook 'find-file-hook #'gs/review-refresh)
(add-hook 'after-save-hook #'gs/review-refresh)
(add-hook 'doom-switch-buffer-hook #'gs/review-refresh)
(add-function :after after-focus-change-function
              (lambda ()
                (when (frame-focus-state)
                  (with-current-buffer (window-buffer (selected-window))
                    (gs/review-refresh)))))

;;; Keys (nvim: v <CR>, <leader>r{o,e,d})

(map! :v "RET" #'gs/review-add)
(map! :leader
      (:prefix-map ("r" . "review")
       :desc "Add comment"          :nv "a" #'gs/review-add
       :desc "List queue"           :n  "o" #'gs/review-list
       :desc "Edit comment"         :n  "e" #'gs/review-edit
       :desc "Withdraw comment"     :n  "d" #'gs/review-withdraw
       :desc "Refresh marks"        :n  "r" #'gs/review-refresh-all
       :desc "Submit review"        :n  "s" #'gs/review-submit))
