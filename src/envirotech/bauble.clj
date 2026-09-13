(ns envirotech.bauble
  (:require [clojure.edn :as edn]
            [clojure.java.io :as io]
            [clojure.java.shell :as shell]
            [clojure.string :as str]
            [shadow.resource :as resource]))

(def sources-path "shaders/bauble.edn")

;; The build hook and inline macro share diagnostics for the current build.
(defonce compilation-warnings (atom {}))

(defn- output-name [source]
  (str/replace source #"\.janet$" ".glsl"))

(defn- uniform-name [name]
  ;; Match Bauble's GLSL identifier escaping.
  (->> (map-indexed
        (fn [i ch]
          (if-let [word ({\+ "plus" \* "star" \$ "dollar" \/ "slash"} ch)]
            (if (= 1 (count name)) (str ch)
                (str (when (pos? i) "_") word (when (< i (dec (count name))) "_")))
            (if (= ch \-) "_" (str ch)))) name)
       (apply str)))

(defn shader-uniforms [glsl]
  (into {}
        (for [line (str/split-lines glsl)
              :when (str/starts-with? line "// envirotech-default ")
              :let [[name value] (edn/read-string
                                 (str "[" (subs line (count "// envirotech-default ")) "]"))]]
          [(uniform-name name) value])))

(defn compile-shader! [directory source]
  (let [input (io/file directory source)
        output (io/file directory (output-name source))
        prelude (slurp (io/resource "shaders/uniforms.janet"))
        {:keys [exit out err]} (shell/sh "bauble" "compile"
                                       :in (str prelude "\n" (slurp input)))]
    (when-not (zero? exit)
      (throw (ex-info (str "Bauble compilation failed for " source ":\n" err out)
                      {:source source :exit exit})))
    ;; Keep #version first and store defaults in the same artifact as the GLSL.
    (let [lines (str/split-lines out)
          defaults (filter #(str/starts-with? % "// envirotech-default ") lines)
          glsl (str (str/join "\n" (remove #(str/starts-with? % "// envirotech-default ") lines))
                    "\n" (when (seq defaults) (str (str/join "\n" defaults) "\n")))]
      (shader-uniforms glsl)
      (when (or (not (.exists output)) (not= glsl (slurp output)))
        (spit output glsl)))))

(defn compile-hook
  {:shadow.build/stage :compile-prepare}
  [state]
  (let [config (io/resource sources-path)
        directory (.getParentFile (io/file config))]
    (doseq [source (edn/read-string (slurp config))]
      (try
        (compile-shader! directory source)
        (swap! compilation-warnings dissoc source)
        (catch clojure.lang.ExceptionInfo error
          ;; A bad edit should leave the existing shader available to hot reload.
          (if (and (= :dev (:shadow.build/mode state))
                   (:exit (ex-data error))
                   (.isFile (io/file directory (output-name source))))
            (let [warning (str (.getMessage error) "\nKeeping existing GLSL for " source)]
              (swap! compilation-warnings assoc source warning)
              (binding [*out* *err*]
                (println warning)))
            (throw error))))))
  state)

(defmacro inline-bauble [source]
  (let [sources (edn/read-string (resource/slurp-resource &env sources-path))]
    (when-not (some #{source} sources)
      (throw (ex-info "Bauble source is not listed in bauble.edn" {:source source})))
    (doseq [input sources]
      (resource/slurp-resource &env (str "shaders/" input)))
    (resource/slurp-resource &env "shaders/uniforms.janet")
    (let [glsl (resource/slurp-resource &env (str "shaders/" (output-name source)))
          shader {:source glsl :uniforms (shader-uniforms glsl)}
          warning (get @compilation-warnings source)]
      (if warning
        `(do (js/console.warn ~warning) ~shader)
        shader))))
