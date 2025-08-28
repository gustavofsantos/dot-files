#!/usr/bin/env bb

;; This script reads an EDN data structure from a string argument
;; and prints it back to the console, formatted for readability.
;;
;; ---
;; How to run:
;; 1. Save the file (e.g., as format-edn.clj)
;; 2. Make it executable: chmod +x format-edn.clj
;; 3. Run it with a quoted EDN string:
;;    ./format-edn.clj "{:a 1 :b [2 3]}"
;; ---

(require '[clojure.edn :as edn]
         '[clojure.pprint :as pprint])

;; Get the first command-line argument.
(let [edn-string (first *command-line-args*)]
  ;; Check if the user provided any input string.
  (if-not (seq edn-string)
    ;; If no input, print usage instructions and exit with an error code.
    (do
      (println "Usage: ./format-edn.clj \"<edn-string>\"")
      (println "\nExample: ./format-edn.clj \"{:a 1 :b [2 3 {:c 4}]}\"")
      (System/exit 1))
    ;; If input is present, try to parse and print it.
    (try
      ;; Read the string into a Clojure data structure.
      (let [data (edn/read-string edn-string)]
        ;; Pretty-print the resulting data structure to standard output.
        (pprint/pprint data))
      ;; If the string is not valid EDN, catch the exception.
      (catch Exception e
        (println "Error: Invalid EDN string.")
        (println (.getMessage e))
        (System/exit 1)))))
