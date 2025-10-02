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
