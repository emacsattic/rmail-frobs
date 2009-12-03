;; rmail-frobs.el --- random RMAIL utilities
;; Author: Noah Friedman <friedman@prep.ai.mit.edu>
;; Created: 1995-04-21
;; Public domain

;; $Id: rmail-frobs.el,v 1.1 1995/06/01 14:56:05 friedman Exp $

;; lpr.el doesn't provide itself.
(or (fboundp 'print-region-1)
    (load "lpr"))

(defvar rmail-frobs-message-separator "^\C-_\f?$")
(defvar rmail-frobs-message-begin "^\\*\\*\\* EOOH \\*\\*\\*\n")
(defvar rmail-frobs-folder-end "^\C-_$")
(defvar rmail-frobs-buffer-name-format "*%s Print*")

(defun print-rmail-folder (&optional printer)
  (interactive
   (list (let* ((def (getenv "PRINTER"))
                (pr (read-from-minibuffer
                     (format "Print folder on printer%s: "
                             (if def (format " (default %s)" def) "")))))
           (if (and (string= pr "") def)
               def
             pr))))

  (and (string= printer "")
       (setq printer nil))

  (save-match-data
    (save-excursion
      (save-restriction
        (let ((msglist nil)
              (msgcount 0)
              msgtail
              rmailbuf
              nbuf)

          (cond ((eq major-mode 'rmail-summary-mode)
                 (setq msglist (rmail-frobs-get-summary-message-numbers))
                 (setq rmailbuf rmail-buffer))
                ((eq major-mode 'rmail-mode)
                 (setq rmailbuf (current-buffer)))
                (t
                 (error "Not in rmail buffer")))

          (setq nbuf
                (generate-new-buffer (format rmail-frobs-buffer-name-format
                                             (buffer-name rmailbuf))))

          ;; might be in summary buffer
          (set-buffer rmailbuf)
          (widen)

          (set-buffer nbuf)
          (fundamental-mode)
          (buffer-disable-undo)
          (insert-buffer rmailbuf)
          (goto-char (point-min))

          ;; delete babyl header
          (re-search-forward rmail-frobs-message-separator)
          (delete-region (point-min) (match-beginning 0))
          (goto-char (point-min))

          (setq msgtail msglist)
          (while (re-search-forward rmail-frobs-message-separator nil t)
            (let ((p (match-beginning 0)))
              (setq msgcount (1+ msgcount))
              (cond ((or (eobp)
                         (looking-at rmail-frobs-folder-end))
                     (goto-char (point-max)))
                    ((null msglist)
                     (re-search-forward rmail-frobs-message-begin)
                     (delete-region p (match-end 0))
                     (insert "\f\n"))
                    ((setq msgtail (memq msgcount msglist))
                     ;; speed up later searches by shortening list
                     (setq msglist msgtail)
                     (re-search-forward rmail-frobs-message-begin)
                     (delete-region p (match-end 0))
                     (insert "\f\n"))
                    (t
                     ;; delete message outright
                     (re-search-forward rmail-frobs-message-separator nil t 1)
                     (delete-region p (match-beginning 0))
                     (beginning-of-line)))))

          (goto-char (point-min))
          (and (looking-at "^\f\n")
               (delete-char 2))

          (goto-char (point-max))
          (beginning-of-line)
          (and (looking-at rmail-frobs-folder-end)
               (delete-region (match-beginning 0) (match-end 0)))

          (let ((lpr-switches (and printer (list (concat "-P" printer)))))
            ;; Use t for page-headers arg, to get buffer name and page
            ;; numbers at the top.  Otherwise, we could just use lpr-buffer.
            (print-region-1 (point-min) (point-max) lpr-switches t))
          (kill-buffer nbuf)
          (message "Sent to printer %s" (or printer "")))))))

(defun rmail-frobs-get-summary-message-numbers ()
  (let ((msglist nil)
        beg end)
    (save-excursion
      (save-match-data
        (goto-char (point-min))
        (while (not (looking-at "^$"))
          (skip-chars-forward "^0-9")
          (setq beg (point))
          (skip-chars-forward "0-9")
          (setq end (point))
          (setq msglist (cons (string-to-int (buffer-substring beg end))
                              msglist))
          (forward-line 1))))
    (nreverse msglist)))

(provide 'rmail-frobs)

;; rmail-frobs.el ends here
