;; extends

[
  "~"
  "~@"
  "#"
] @punctuation.special

(kwd_lit namespace: (kwd_ns) @keyword_symbol.namespace
         name: (kwd_name) @keyword_symbol.name
         (#set! "priority" 130))

(kwd_lit name: (kwd_name) @keyword_symbol.name
         (#set! "priority" 120))

(kwd_lit) @keyword_symbol

(sym_lit namespace: (sym_ns) @quilified_symbol.namespace
         name: (sym_name) @quilified_symbol.name
         (#set! "priority" 130))

(sym_lit namespace: (sym_ns)
         name: (sym_name) @quilified_symbol
         (#set! "priority" 120))

(derefing_lit value: (sym_lit name: (sym_name)) @deref.name
          (#set! "priority" 130))

(derefing_lit) @deref

;; extends
(list_lit
  value: (sym_lit) @_keyword.function
  (#any-of? @_keyword.function "fn" "fn*" "defn" "defn-")
  value: (sym_lit)? @AlabasterDefinition
  value: (vec_lit)
  (str_lit)? @comment)

(list_lit
  value: (sym_lit) @_keyword.function
  (#any-of? @_keyword.function "fn" "fn*" "defn" "defn-")
  value: (sym_lit)? @AlabasterDefinition
  value: (list_lit))

(list_lit
  value: (sym_lit) @_keyword.function
  (#eq? @_keyword.function "defmacro")
  value: (sym_lit)? @AlabasterDefinition
  value: (vec_lit)
  (str_lit)? @comment)

(list_lit
  value: (sym_lit) @_include
  (#eq? @_include "ns")
  value: (sym_lit) @AlabasterDefinition)

(list_lit
  value: (kwd_lit) @AlabasterConstant)
(vec_lit
  value: (kwd_lit) @AlabasterConstant)
(map_lit
  value: (kwd_lit) @AlabasterConstant)
