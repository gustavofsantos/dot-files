#!/usr/bin/env bb

(require '[clojure.java.io :as io])

(let [file (first *command-line-args*)]
  (if-not file
    (do
      (println "Usage: ./check.clj <file-to-check.clj>")
      (System/exit 1))
    (try
      (with-open [rdr (java.io.PushbackReader. (io/reader file))]
        ;; Loop and read every form.
        ;; The read function will throw an exception on syntax errors.
        ;; The doall forces the lazy sequence of reads to be fully realized.
        (doall (take-while #(not (identical? % ::eof))
                           (repeatedly #(read rdr false ::eof)))))
      (println "✅ Syntax OK:" file)
      (catch Exception e
        (println "❌ Syntax ERROR in" file)
        (println (.getMessage e))
        (System/exit 1)))))
