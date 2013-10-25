; 78 columns:
; 3456789012345678901234567890123456789012345678901234567890123456789012345678

;(menu-bar-mode -1)
;(tool-bar-mode -1)
;(scroll-bar-mode -1)

(defun toggle-fullscreen (&optional f)
  (interactive)
  (let ((current-value (frame-parameter nil 'fullscreen)))
       (set-frame-parameter nil 'fullscreen
                            (if (equal 'fullboth current-value)
                                (if (boundp 'old-fullscreen) old-fullscreen nil)
                                (progn (setq old-fullscreen current-value)
                                       'fullboth)))))
(global-set-key [f11] 'toggle-fullscreen)
; Make new frames fullscreen by default. Note: this hook doesn't do
; anything to the initial frame if it's in your .emacs, since that file is
; read _after_ the initial frame is created.
(add-hook 'after-make-frame-functions 'toggle-fullscreen)

;; backups
(setq backup-directory-alist `(("." . "~/.emacs-saves")))

;; vim bindings
(add-to-list 'load-path "~/.emacs.d/evil")
(require 'evil)
;(evil-set-initial-state 'text-mode 'emacs)
(evil-mode 1)

(custom-set-variables
  '(inhibit-startup-screen t))
(custom-set-faces
  )

;; programming
(global-set-key "\M-C" 'compile)
(global-set-key "\C-^" 'next-error)
(global-set-key "\C-\M-g" 'goto-line)

;; use spaces instead of tabs
(setq-default indent-tabs-mode nil)

;; haskell

(setq auto-mode-alist
      (append auto-mode-alist
              '(("\\.[hg]s$"  . haskell-mode)
                ("\\.hic?$"     . haskell-mode)
                ("\\.hsc$"     . haskell-mode)
  ("\\.chs$"    . haskell-mode)
                ("\\.l[hg]s$" . literate-haskell-mode))))
(autoload 'haskell-mode "haskell-mode"
   "Major mode for editing Haskell scripts." t)
(autoload 'literate-haskell-mode "haskell-mode"
   "Major mode for editing literate Haskell scripts." t)

;adding the following lines according to which modules you want to use:
(require 'inf-haskell)

(add-hook 'haskell-mode-hook 'turn-on-font-lock)
;(add-hook 'haskell-mode-hook 'turn-off-haskell-decl-scan)
;(add-hook 'haskell-mode-hook 'turn-off-haskell-doc-mode)
(add-hook 'haskell-mode-hook 'turn-on-haskell-indent)
;(add-hook 'haskell-mode-hook 'turn-on-haskell-simple-indent)
;(add-hook 'haskell-mode-hook 'turn-on-haskell-hugs)
(add-hook 'haskell-mode-hook 'turn-on-haskell-ghci)
(add-hook 'haskell-mode-hook
   (function
    (lambda ()
      (setq haskell-program-name "ghci")
      (setq haskell-ghci-program-name "ghci"))))
