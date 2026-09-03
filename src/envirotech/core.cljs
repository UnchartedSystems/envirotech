(ns envirotech.core
  (:require [replicant.dom :as r]
            [reitit.frontend.easy :as rfe]
            [envirotech.routes :as routes]))

(defonce current-route (atom nil))

(def bookends-style ["bg-neutral-900" "text-white"])

(defn nav-entry [current-name route-name label]
  (if (not= current-name route-name)
    [:a {:href (routes/href route-name) :aria-label "page"}
     label]
    ;; Default Home Link
    [:a {:href (routes/href ::routes/home) :aria-label "page"}
     "Home"]))

(defn header [current-name]
  [:header {:class bookends-style}
   [:h2
    [:a {:href (routes/href ::routes/home) :aria-label "page"}
     "Envirotech"]]
   [:nav {:aria-label "Primary navigation"}
      (nav-entry current-name ::routes/bitumen "Bitumen")
      (nav-entry current-name ::routes/hydrogen "Hydrogen")]])

(defn footer []
  [:footer {:class bookends-style}
   [:h2 "Contact Us"]])

(defn app [route-match]
  (let [{:keys [name view]} (:data route-match)]
    (list
     (header name)
     (if view
       (view)
       (routes/not-found))
     (footer))))

(defn render! []
  (r/render
   (js/document.getElementById "content")
   (app @current-route)))

(defn on-navigate [route-match _history]
  (reset! current-route route-match)
  (set! (.-title js/document)
        (or (get-in route-match [:data :title])
            "Page not found | Envirotech"))
  (render!))

(defn start-router! []
  (rfe/start! routes/router on-navigate {:use-fragment false}))

(defn ^:dev/after-load reload! []
  (start-router!))

(defn style-roots []
  ;; canvas element styling
  (.add (.-classList (js/document.getElementById "background"))
        "fixed" "inset-0"
        "-z-10"
        "w-full" "h-dvh"
        "bg-green-800")
  ;; main element styling
  (.add (.-classList (js/document.getElementById "content"))
        "mx-auto" "lg:mt-16"
        "w-full" "max-w-5xl"
        "flex" "flex-col"
        "rounded-sm" "overflow-hidden"
        "bg-white" "shadow-lg"))

(defn init! []
  (style-roots)
  (start-router!))

