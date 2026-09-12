(ns envirotech.bitumen
  (:require [envirotech.misc :refer [lorum-sm]])
  (:require-macros [envirotech.markdown :refer [inline-article]]))

(def root
  [:main
   [:section
    {:class ["bg-orange-800" "text-white" "p-frame"]}
    [:h1 "Bitumen"]
    lorum-sm]
   (inline-article "articles/bitumen.md")])
