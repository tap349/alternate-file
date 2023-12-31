;;; alternate-file.el --- Find alternate file -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Free Software Foundation, Inc.

;; Author: Alexey Terekhov <alexey.terekhov.tap349@gmail.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: convenience, lisp, test
;; URL: https://github.com/tap349/alternate-file

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package allows to find alternate file - usually this means to find
;; test file for implementation file and vice versa.
;;
;; This functionality is similar to that provided by projectile package and
;; its projectile-toggle-between-implementation-and-test function but this
;; package is much simpler and doesn't use complicated heuristic to find test
;; files.
;;
;; Instead it relies on user-supplied rules in af-file-settings variable -
;; user should specify implementation directory, test directory and suffix of
;; test files for each major mode manually.  As of now test prefixes are not
;; supported because I don't use such languages but feel free to open a new
;; issue in case you need them.
;;
;; Another goal of creating this package is to avoid using projectile package
;; in favour of built-in project.el - user should configure the latter because
;; this package uses it to find the root of current project.
;;
;; Installation and sample configuration:
;;
;;    (use-package alternate-file
;;      :straight (eldoc-box :type git :host github :repo "tap349/alternate-file")
;;      :after evil
;;      :custom
;;      (af-settings '((clojure-mode . ("src" "test" "_test"))
;;                     (go-mode . ("{}" "{}" "_test"))
;;                     (kotlin-mode . ("src/main" "src/test" "Test"))))
;;
;;      :bind
;;      (:map evil-normal-state-map
;;        ("<leader>," . af-find-alternate-file)))

;;; Code:

(require 'project)
(eval-when-compile (require 'subr-x))

(defgroup alternate-file nil
  "Find alternate file."
  :prefix "af-"
  :group 'convenience)

(defcustom af-settings nil
  "Alist of alternate-file settings per major mode."
  :type 'alist)

(defun af--alternate-file-dir (file-path impl-dir test-dir)
  "Return alternate directory for FILE-PATH.
Use IMPL-DIR and TEST-DIR to find implementation and test directories."
  (let ((file-dir (file-name-directory file-path)))
    (if (or (string= impl-dir "{}") (string= test-dir "{}"))
        file-dir
      (let ((old-base-dir (cond ((string-prefix-p impl-dir file-dir) impl-dir)
                                ((string-prefix-p test-dir file-dir) test-dir)
                                (t (error "Can't find current base dir"))))
            (new-base-dir (cond ((string-prefix-p impl-dir file-dir) test-dir)
                                ((string-prefix-p test-dir file-dir) impl-dir)
                                (t (error "Can't find alternate base dir")))))
        (replace-regexp-in-string (concat "^" old-base-dir) new-base-dir file-dir)))))

(defun af--alternate-file-name (file-path test-suffix)
  "Return alternate filename for FILE-PATH.
Use TEST-SUFFIX to find test file."
  (let* ((file-name (file-name-nondirectory file-path))
         (base-name (file-name-sans-extension file-name))
         (ext (file-name-extension file-name)))
    (if (string-suffix-p test-suffix base-name)
        (concat (string-remove-suffix test-suffix base-name) "." ext)
      (concat base-name test-suffix "." ext))))

(defun af--alternate-file-path (impl-dir test-dir test-suffix)
  "Return absolute path of alternate file.
Use IMPL-DIR, TEST-DIR and TEST-SUFFIX to find implementation directory,
test directory and test file accordingly."
  (let* ((root-dir (project-root (project-current)))
         (file-path (file-relative-name buffer-file-name root-dir))
         (alt-file-dir (af--alternate-file-dir file-path impl-dir test-dir))
         (alt-file-name (af--alternate-file-name file-path test-suffix))
         (alt-file-path (concat alt-file-dir alt-file-name)))
    (expand-file-name alt-file-path root-dir)))

;;;###autoload
(defun af-find-alternate-file ()
  "Find alternate file, create one if it doesn't already exist."
  (interactive)
  (let ((mode-settings (alist-get major-mode af-settings)))
    (or mode-settings (error "Major mode %s not supported" major-mode))
    (find-file (apply #'af--alternate-file-path mode-settings))))

(provide 'alternate-file)

;;; alternate-file.el ends here
