(ns envirotech.routes
  (:require [envirotech.home :as home]
            [envirotech.hydrogen :as hydrogen]
            [envirotech.bitumen :as bitumen]
            [reitit.frontend :as rf]
            [reitit.frontend.easy :refer [href]]))

(def routes
  ["/"
   ["" {:name :home
        :title "Envirotech"
        :view home/root}]
   ["bitumen" {:name :bitumen
               :title "Bitumen | Envirotech"
               :view bitumen/root}]
   ["hydrogen" {:name :hydrogen
                :title "Hydrogen | Envirotech"
                :view hydrogen/root}]])

(def router
  (rf/router routes))

(defn not-found []
  [:section
   [:h2 "Page not found"]
   [:p "The page you requested does not exist."]
   [:a {:href (href :home)} "Return home"]])
