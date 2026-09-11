(ns envirotech.home
  (:require [envirotech.misc :refer [lorum-sm lorum-md lorum-lg]]
            [reitit.frontend.easy :refer [href]]))

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
     [:a
      {:class ["hover:bg-neutral-100" "md:flex-1"
               "max-md:pb-psm"]
       :href (href :bitumen)
       :aria-label "page"}
      [:h3 "Bitumen"]
      lorum-md]
     [:a
      {:class ["hover:bg-neutral-100" "md:flex-1"]
       :href (href :hydrogen)
       :aria-label "page"}
      [:h3 "Hydrogen"]
      lorum-md]]]
   #_[:section
      [:h2 "News"]]
   #_[:section
      [:h2 "Partners"]]])
