;extends

; query
;; generic comment-based language injection
;; place a comment like `# sql`, `# javascript`, `# html` on the line above the string.
;; the comment text (minus `#`) becomes the injection language name.
;; language names must be lowercase (neovim tree-sitter parser names are lowercase).
;; examples: `# sql`, `# javascript`, `# typescript`, `# html`, `# css`, `# python`
((comment) @injection.language
  (#lua-match? @injection.language "^#%s*%a+%s*$")
  (#gsub! @injection.language "^#%s*(%a+)%s*$" "%1")
  .
  (expression_statement
    (assignment
      right: (string
        (string_content) @injection.content))))

; query
;; variable-name suffix injection (no comment needed)
;; matches UPPER_CASE constants whose name ends in a language suffix.
;; rename e.g. `DETECT_CREATIVE_TYPE_SCRIPT` -> `DETECT_CREATIVE_TYPE_JS` to use this.

((expression_statement
  (assignment
    left: (identifier) @_var
    right: (string
      (string_content) @injection.content)))
  (#lua-match? @_var "_SQL$")
  (#set! injection.language "sql"))

((expression_statement
  (assignment
    left: (identifier) @_var
    right: (string
      (string_content) @injection.content)))
  (#lua-match? @_var "_JAVASCRIPT$")
  (#set! injection.language "javascript"))

((expression_statement
  (assignment
    left: (identifier) @_var
    right: (string
      (string_content) @injection.content)))
  (#lua-match? @_var "_JS$")
  (#set! injection.language "javascript"))

((expression_statement
  (assignment
    left: (identifier) @_var
    right: (string
      (string_content) @injection.content)))
  (#lua-match? @_var "_TYPESCRIPT$")
  (#set! injection.language "typescript"))

((expression_statement
  (assignment
    left: (identifier) @_var
    right: (string
      (string_content) @injection.content)))
  (#lua-match? @_var "_TS$")
  (#set! injection.language "typescript"))

((expression_statement
  (assignment
    left: (identifier) @_var
    right: (string
      (string_content) @injection.content)))
  (#lua-match? @_var "_HTML$")
  (#set! injection.language "html"))

((expression_statement
  (assignment
    left: (identifier) @_var
    right: (string
      (string_content) @injection.content)))
  (#lua-match? @_var "_CSS$")
  (#set! injection.language "css"))

((expression_statement
  (assignment
    left: (identifier) @_var
    right: (string
      (string_content) @injection.content)))
  (#lua-match? @_var "_PYTHON$")
  (#set! injection.language "python"))

; query
;; string sql injection
((string_content) @injection.content 
                   (#match? @injection.content "^(\r\n|\r|\n)*-{2,}( )*[sS][qQ][lL]")
                   (#set! injection.language "sql"))

; query
;; string javascript injection
((string_content) @injection.content 
                   (#match? @injection.content "^(\r\n|\r|\n)*/{2,}( )*[jJ][aA][vV][aA][sS][cC][rR][iI][pP][tT]")
                   (#set! injection.language "javascript"))

; query
;; string typescript injection
((string_content) @injection.content 
                   (#match? @injection.content "^(\r\n|\r|\n)//+( )*[tT][yY][pP][eE][sS][cC][rR][iI][pP][tT]")
                   (#set! injection.language "typescript"))

; query
;; string html injection
((string_content) @injection.content 
                   (#match? @injection.content "^(\r\n|\r|\n)\\<\\!-{2,}( )*[hH][tT][mM][lL]( )*-{2,}\\>")
                   (#set! injection.language "html"))

; query
;; string css injection
((string_content) @injection.content 
                   (#match? @injection.content "^(\r\n|\r|\n)/\\*+( )*[cC][sS][sS]( )*\\*+/")
                   (#set! injection.language "css"))

; query
;; string python injection
((string_content) @injection.content 
                   (#match? @injection.content "^(\r\n|\r|\n)*#+( )*[pP][yY][tT][hH][oO][nN]")
                   (#set! injection.language "python"))
