# alternate-file

## Introduction

`alternate-file` allows to find alternate file - usually this means to find test
file for implementation file and vice versa.

This functionality is similar to that provided by `projectile` package and its
`projectile-toggle-between-implementation-and-test` function but this package is
much simpler and doesn't use complicated heuristic to find test files.

Instead it relies on user-supplied rules in `af-settings` variable - user should
specify implementation directory, test directory and suffix of test files for
each major mode manually. As of now test prefixes are not supported because I
don't use such languages but feel free to open a new issue in case you need them.

## Installation and example configuration

```emacs-lisp
(use-package alternate-file
  :straight (alternate-file :type git :host github :repo "tap349/alternate-file")
  :after evil
  :custom
  (af-settings '((clojure-mode . ("src" "test" "_test"))
                 (go-mode . ("{}" "{}" "_test"))
                 (kotlin-mode . ("src/main" "src/test" "Test"))))

  :bind
  (:map evil-normal-state-map
    ("<leader>," . af-find-alternate-file)))
```

`{}` means "use the same directory for implementation and test directories" -
this is useful, say, for `go-mode` in which implementation and test files are
usually stored in the same directory but it can be either `internal` or `pkg`.
