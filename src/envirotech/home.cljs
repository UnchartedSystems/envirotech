(ns envirotech.home
  (:require [envirotech.misc :refer [lorum-sm lorum-tmd]]
            [reitit.frontend.easy :refer [href]]))


(defn tech [name route description]
  [:a
   {:class ["group" "hover:bg-neutral-100"
            "md:flex-1" "w-fit" "p-frame"]
    :href (href route)
    :aria-label (str name " page")}
   [:h3
    {:class ["group-hover:text-blue-600"]}
    name]
   [:p
    {:class ["text-pretty"]}
    description]])

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
    {:class ["flex" "flex-col" "md:flex-row" "min-w-0"]}
    (tech "Bitumen" :bitumen lorum-tmd)
    (tech "Hydrogen" :hydrogen lorum-tmd)]
   #_[:section
      [:h2 "News"]]
   #_[:section
      [:h2 "Partners"]]])
