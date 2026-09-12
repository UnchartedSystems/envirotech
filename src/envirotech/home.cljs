(ns envirotech.home
  (:require [envirotech.misc :refer [lorum-sm lorum-md lorum-lg]]
            [reitit.frontend.easy :refer [href]]))


(defn tech [name route description]
  [:a
   {:class ["group" "rounded-md"
            "hover:bg-neutral-100" "md:flex-1"
            "w-fit" "max-md:pb-psm"]
    :href (href route)
    :aria-label "page"}
   [:h3
    {:class ["group-hover:underline"]}
    name]
   description])

(defn root []
  [:main
   [:section
    {:class ["bg-blue-700" "text-white"
             "px-frame" "pt-p2xl" "pb-plg"]}
    [:h1
     {:class ["text-balance" "pb-psm"]}
     "Technology for the future of energy."]
    lorum-sm]
   [:section
    {:class ["p-frame"]}
    [:div
     {:class ["flex" "flex-col" "md:flex-row" "min-w-0"]}
     (tech "Bitumen" :bitumen lorum-md)
     (tech "Hydrogen" :hydrogen lorum-md)
     ]]
   #_[:section
      [:h2 "News"]]
   #_[:section
      [:h2 "Partners"]]])
