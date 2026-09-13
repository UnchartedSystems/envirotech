(ns envirotech.bauble
  (:require [clojure.edn :as edn]
            [clojure.java.io :as io]
            [clojure.java.shell :as shell]
            [clojure.string :as str]
            [shadow.resource :as resource]))

(def sources-path "shaders/bauble.edn")

(defn- output-name [source]
  (str/replace source #"\.janet$" ".glsl"))

(defn compile-shader! [directory source]
  (let [input (io/file directory source)
        output (io/file directory (output-name source))
        {:keys [exit out err]} (shell/sh "bauble" "compile" (.getPath input))]
    (when-not (zero? exit)
      (throw (ex-info (str "Bauble compilation failed for " source ":\n" err out)
                      {:source source :exit exit})))
    (when (or (not (.exists output)) (not= out (slurp output)))
      (spit output out))))

(defn compile-hook
  {:shadow.build/stage :compile-prepare}
  [state]
  (let [config (io/resource sources-path)
        directory (.getParentFile (io/file config))]
    (doseq [source (edn/read-string (slurp config))]
      (compile-shader! directory source)))
  state)

(defmacro inline-bauble [source]
  (let [sources (edn/read-string (resource/slurp-resource &env sources-path))]
    (when-not (some #{source} sources)
      (throw (ex-info "Bauble source is not listed in bauble.edn" {:source source})))
    (doseq [input sources]
      (resource/slurp-resource &env (str "shaders/" input)))
    (resource/slurp-resource &env (str "shaders/" (output-name source)))))
