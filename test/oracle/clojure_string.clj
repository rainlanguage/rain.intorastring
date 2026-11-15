;; SPDX-License-Identifier: LicenseRef-DCL-1.0
;; SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd

;; One byte per char (ISO-8859-1); exits non zero on a result char above 0xFF.
(ns clojure-string
  (:require [camel-snake-kebab.core :as csk]
            [clojure.edn :as edn]
            [clojure.string :as str]
            [cuerdas.core :as cuerdas]))

(defn hex->string [hex]
  (apply str (map #(char (Integer/parseInt (apply str %) 16)) (partition 2 (subs hex 2)))))

(defn string->bytes [s]
  (mapv (fn [c]
          (when (> (int c) 0xff)
            (binding [*out* *err*]
              (println (format "Clojure result %s has char U+%04X above 0xFF" (pr-str s) (int c))))
            (System/exit 1))
          (int c))
        s))

(defn word [n]
  (format "%064x" (biginteger n)))

(defn abi-bytes [bs]
  (let [hex (apply str (map #(format "%02x" %) bs))
        padding (mod (- (count hex)) 64)]
    (str (word (count bs)) hex (apply str (repeat padding "0")))))

(defn ok-string [s]
  (str (word 1) (word 64) (abi-bytes (string->bytes s))))

(def thrown
  (str (word 0) (word 64) (abi-bytes [])))

(def string-fns
  {"triml" str/triml
   "trimr" str/trimr
   "trim" str/trim
   "lower-case" str/lower-case
   "upper-case" str/upper-case
   "camel-case" csk/->camelCase
   "pascal-case" csk/->PascalCase
   "snake-case" csk/->snake_case
   "screaming-snake-case" csk/->SCREAMING_SNAKE_CASE
   "kebab-case" csk/->kebab-case})

(def string2-fns
  {"str" str
   "strip-prefix" cuerdas/strip-prefix
   "strip-suffix" cuerdas/strip-suffix})

(def predicates
  {"starts-with?" str/starts-with?
   "ends-with?" str/ends-with?
   "includes?" str/includes?})

(let [[op & args] *command-line-args*
      [a b c] args]
  (println
   (str "0x"
        (cond
          (= op "count") (word (count (hex->string a)))
          (predicates op) (word (if ((predicates op) (hex->string a) (hex->string b)) 1 0))
          (string-fns op) (ok-string ((string-fns op) (hex->string a)))
          (string2-fns op) (ok-string ((string2-fns op) (hex->string a) (hex->string b)))
          (= op "subs") (let [s (hex->string a)
                              result (try (subs s (edn/read-string b) (edn/read-string c))
                                          (catch Exception _ ::thrown))]
                          (if (= result ::thrown) thrown (ok-string result)))
          :else (throw (ex-info (str "Unknown op " op) {}))))))
