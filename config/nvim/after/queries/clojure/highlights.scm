;; extends

;; -------------------------------------------------------------------
;; Tier 1: Recede (Structural Noise)
;; -------------------------------------------------------------------
;; Highlights reader macros and dispatch characters
[
  "~"
  "~@"
  "#"
  "'"
  "`"
] @punctuation.special

;; -------------------------------------------------------------------
;; Tier 3: Highlight (Data Literals)
;; -------------------------------------------------------------------
;; This is the *only* keyword query you need.
;; It correctly captures :foo, :bar/baz, and ::baz as a single
;; "data" token, which your Lua file maps to @kw
; (kwd_lit) @kw
;
; (kwd_lit namespace: (kwd_ns) @keyword_symbol.namespace
;          name: (kwd_name) @keyword_symbol.name
;          (#set! "priority" 130))
;
; (kwd_lit name: (kwd_name) @keyword_symbol.name
;          (#set! "priority" 120))
;
; (sym_lit namespace: (sym_ns) @qualified_symbol.namespace
;          name: (sym_name) @qualified_symbol.name
;          (#set! "priority" 120))

;; -------------------------------------------------------------------
;; Tier 4: Emphasize (Definitions & Logic)
;; -------------------------------------------------------------------
;; These queries are the most important for efficiency.
;; They capture the *first symbol* in a list to determine its role.

;; Capture "Definitions" (Tier 4, Group 3)
;; (defn ...), (def ...)
; (
;   (list_lit
;     (sym_lit (sym_name) @constructor.clojure)
;     .
;   )
;   (#any-of? @constructor.clojure
;     "def" "defn" "defn-" "defmacro" "defmulti" "defmethod" "defntraced"
;     "defonce" "defprotocol" "deftype" "defrecord" "defstruct" "trace/defntraced")
; )
;
; ;; Capture the *name* of the function/var being defined
; ;; (defn my-func ...) -> highlights "my-func"
; (
;   (list_lit
;     (sym_lit (sym_name) @constructor.clojure) ; e.g., "defn"
;     (sym_lit (sym_name) @function) ; e.g., "my-func"
;     .
;   )
;   (#any-of? @constructor.clojure "defn" "defn-" "defmacro" "defntraced" "trace/defntraced")
;   (#set! "priority" 110) ; Higher priority
; )

;; Capture "Special Forms" (Tier 4, Group 1)
;; (if ...), (let ...)
; (
;   (list_lit
;     (sym_lit (sym_name) @keyword.function.clojure)
;     .
;   )
;   (#any-of? @keyword.function.clojure
;     "if" "if-not" "if-let" "if-some"
;     "case" "cond" "condp"
;     "let" "loop" "binding" "letfn"
;     "fn" "reify"
;     "try" "catch" "finally" "throw")
;   (#set! "priority" 105) ; High priority
; )

;; Capture common "Macro" calls (Tier 4, distinct)
;; (-> ...), (when ...)
; (
;   (list_lit
;     (sym_lit (sym_name) @function.macro.clojure)
;     .
;   )
;   (#any-of? @function.macro.clojure
;     "->" "->>" "some->" "some->>" "as->"
;     "comment" "with-open" "with-out-str"
;     "when" "when-not" "when-let" "when-some"
;     "for" "doseq" "dotimes")
;   (#set! "priority" 100) ; Lower priority than special forms
; )

;; -------------------------------------------------------------------
;; Mute :require and :import blocks in (ns ...)
;; -------------------------------------------------------------------
; (list_lit
;   value: (kwd_lit) @kwd_lit.clojure
;   (#any-of? @kwd_lit.clojure ":require" ":import")
;   .
;   value: (vec_lit) @required.clojure
;   (#set! "priority" 200))

;; -------------------------------------------------------------------
;; Misc
;; -------------------------------------------------------------------
;; Captures @foo
; (derefing_lit) @deref
;; Captures foo in @foo
; (derefing_lit value: (sym_lit name: (sym_name)) @deref.name
;   (#set! "priority" 130))

;; extends
; (list_lit
;   value: (sym_lit) @_keyword.function
;   (#any-of? @_keyword.function "fn" "fn*" "defn" "defn-")
;   value: (sym_lit)? @AlabasterDefinition
;   value: (vec_lit)
;   (str_lit)? @comment)
;
; (list_lit
;   value: (sym_lit) @_keyword.function
;   (#any-of? @_keyword.function "fn" "fn*" "defn" "defn-")
;   value: (sym_lit)? @AlabasterDefinition
;   value: (list_lit))
;
; (list_lit
;   value: (sym_lit) @_keyword.function
;   (#eq? @_keyword.function "defmacro")
;   value: (sym_lit)? @AlabasterDefinition
;   value: (vec_lit)
;   (str_lit)? @comment)
;
; (list_lit
;   value: (sym_lit) @_include
;   (#eq? @_include "ns")
;   value: (sym_lit) @AlabasterDefinition)
;
; (list_lit
;   value: (kwd_lit) @AlabasterConstant)
; (vec_lit
;   value: (kwd_lit) @AlabasterConstant)
; (map_lit
;   value: (kwd_lit) @AlabasterConstant)
