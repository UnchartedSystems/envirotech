(ns envirotech.markdown
  (:require [nextjournal.markdown :as md]
            [shadow.resource :as resource]))

(def ^:private article-renderers
  (assoc md/default-hiccup-renderers
         :doc
         (partial md/into-hiccup
                  [:article {:class ["p-frame" "article-content"]}])))

(defmacro inline-article
  "Compile a Markdown classpath resource into article Hiccup.
  Shadow tracks the resource for recompilation after Markdown edits."
  [path]
  (when-not (string? path)
    (throw (ex-info "inline-article requires a literal resource path" {:path path})))
  (list 'quote
        (md/->hiccup article-renderers (resource/slurp-resource &env path))))
