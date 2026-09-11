(ns envirotech.bitumen
  (:require [envirotech.misc :refer [lorum-sm lorum-md lorum-lg]]))

(def root
  [:main
   [:section
    {:class ["bg-orange-800" "text-white" "p-frame"]}
    [:h1 "Bitumen"]
    lorum-sm]
   [:article
    {:class ["p-frame"]}
    [:section
     [:h2 "Opening"]
     lorum-lg]
    [:section
     [:h2 "Quick Problem -> Our proposed solution"]
     lorum-lg]
    [:section
     [:h2 "Estimated Benefits & Quick Comparison"]
     lorum-lg]
    [:section
     [:h2 "What do we need to do next?"]
     lorum-lg]
    [:section
     [:h2 "Contact us if you can help us build this"]
     lorum-lg]
    [:section
     [:h2 "Organizations we've partnered with:"]
     lorum-lg]]])

