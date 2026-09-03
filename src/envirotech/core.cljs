(ns envirotech.core
  (:require [replicant.dom :as r]))

(defn app []
  [:main
   [:h1 "test!"]])

(defn render! []
  (r/render
   (js/document.getElementById "app")
   (app)))

(defn init! []
  (render!))
