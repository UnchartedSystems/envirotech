(ns envirotech.core
  (:require [dataspex.core :as dataspex]
            [envirotech.background :as background]
            [envirotech.routes :as routes]
            [replicant.dom :as r]
            [reitit.frontend.easy :refer [href] :as rfe]))

(defonce current-route (atom nil))
(dataspex/inspect "route" current-route)

(defn nav-entry [current-name route-name label]
  [:a
   {:class ["hover:underline"]
    :href (href route-name)
    :aria-label (str label " page")}
   label])

(defn header [current-name]
  [:header
   {:class ["grid" "grid-cols-[auto_minmax(0,1fr)_auto]" "gap-2"]}
   [:img
    {:class ["max-md:h-13" "md:h-15" "w-fit"]
     :src "/envirotech-logo.svg"
     :alt "envirotech logo"}]
   [:h2
    {:class ["flex" "items-center"]}
    [:a
     {:class ["text-left" "ml-3"]
      :href (href :home)
      :aria-label "page"}
     "Envirotech"]]
   [:nav
    {:class ["grid" "grid-rows-2" "flex" "items-center" "pr-5"]
     :aria-label "Primary navigation"}
    (nav-entry current-name :bitumen "Bitumen")
    (nav-entry current-name :hydrogen "Hydrogen")]])

(def footer
  [:footer
   [:h2 "Contact Us"]
   [:p "inquiries@envirotechdme.com"]])

(defn app [route-match]
  (let [{:keys [name view]} (:data route-match)]
    (list
     (header name)
     (if view
       (if (fn? view)
         (view)
         view)
       (routes/not-found))
     footer)))

(defn render! []
  (r/render
   (js/document.getElementById "page")
   (app @current-route)))

(defn on-navigate [route-match _history]
  (reset! current-route route-match)
  (background/set-page! (get-in route-match [:data :name]))
  (set! (.-title js/document)
        (or (get-in route-match [:data :title])
            "Page not found | Envirotech"))
  (render!))

(defn start-router! []
  (rfe/start! routes/router on-navigate {:use-fragment false}))

(defn ^:dev/after-load reload! []
  (background/init!)
  (start-router!))

(defn init! []
  (background/init!)
  (start-router!))
