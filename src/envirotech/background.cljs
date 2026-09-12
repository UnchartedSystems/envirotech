(ns envirotech.background
  (:require [shadow.resource :as resource]))

(def vertex-shader
  (resource/inline "shaders/vertex.glsl"))

(def clouds-shader
  (resource/inline "shaders/clouds.glsl"))

;; Only renderer/clock bookkeeping persists; the shader has no frame history.
(defonce renderer (atom nil))

(defn- compile-shader [gl type source]
  (let [shader (.createShader gl type)]
    (.shaderSource gl shader source)
    (.compileShader gl shader)
    (if (.getShaderParameter gl shader (.-COMPILE_STATUS gl))
      shader
      (let [log (.getShaderInfoLog gl shader)]
        (.deleteShader gl shader)
        (throw (js/Error. (str "Shader compile failed: " log)))))))

(defn- link-program [gl vs-source fs-source]
  (let [vs (compile-shader gl (.-VERTEX_SHADER gl) vs-source)
        fs (compile-shader gl (.-FRAGMENT_SHADER gl) fs-source)
        program (.createProgram gl)]
    (.attachShader gl program vs)
    (.attachShader gl program fs)
    (.linkProgram gl program)
    (if (.getProgramParameter gl program (.-LINK_STATUS gl))
      {:program program :vs vs :fs fs}
      (let [log (.getProgramInfoLog gl program)]
        (.deleteProgram gl program)
        (.deleteShader gl vs)
        (.deleteShader gl fs)
        (throw (js/Error. (str "Program link failed: " log)))))))

(defn- resize-canvas-to-display-size! [canvas]
  (let [display-width (.-clientWidth canvas)
        display-height (.-clientHeight canvas)]
    (when (or (not= (.-width canvas) display-width)
              (not= (.-height canvas) display-height))
      (set! (.-width canvas) display-width)
      (set! (.-height canvas) display-height))))

(defn- draw! []
  (when-let [{:keys [gl program position-loc resolution-loc time-loc
                      buffer elapsed]} @renderer]
    (let [canvas (.-canvas gl)]
      (resize-canvas-to-display-size! canvas)
      (.viewport gl 0 0 (.-width canvas) (.-height canvas))
      (.useProgram gl program)

      (.bindBuffer gl (.-ARRAY_BUFFER gl) buffer)
      (.enableVertexAttribArray gl position-loc)
      (.vertexAttribPointer gl position-loc 3 (.-FLOAT gl) false 0 0)

      (.uniform2f gl resolution-loc (.-width canvas) (.-height canvas))
      (.uniform1f gl time-loc elapsed)

      (.drawArrays gl (.-TRIANGLES gl) 0 6))))

(defn- frame! [timestamp]
  (when (:running? @renderer)
    (swap! renderer
           (fn [{:keys [last-time] :as state}]
             (-> state
                 (update :elapsed + (if last-time
                                      (/ (- timestamp last-time) 1000)
                                      0))
                 (assoc :last-time timestamp :request nil))))
    (draw!)
    (swap! renderer assoc :request (js/requestAnimationFrame frame!))))

(defn set-page! [page]
  (when-let [{:keys [request running?]} @renderer]
    (let [animate? (not (contains? #{:bitumen :hydrogen} page))]
      (when (not= animate? running?)
        (when request (js/cancelAnimationFrame request))
        (swap! renderer assoc :running? animate? :last-time nil :request nil)
        (when animate?
          (swap! renderer assoc :request (js/requestAnimationFrame frame!)))))))

(defn stop! []
  (when-let [{:keys [gl program vs fs buffer request resize]} @renderer]
    (when request (js/cancelAnimationFrame request))
    (when resize (.removeEventListener js/window "resize" resize))
    (when buffer (.deleteBuffer gl buffer))
    (when program
      (when vs (.deleteShader gl vs))
      (when fs (.deleteShader gl fs))
      (.deleteProgram gl program))
    (reset! renderer nil)))

(defn init! []
  (stop!)
  (when-let [canvas (js/document.getElementById "background")]
    (try
      (when-let [gl (.getContext canvas "webgl")]
        (let [{:keys [program vs fs]} (link-program gl vertex-shader clouds-shader)
              position-loc (.getAttribLocation gl program "position")
              resolution-loc (.getUniformLocation gl program "resolution")
              time-loc (.getUniformLocation gl program "time")
              buffer (.createBuffer gl)
              vertices (js/Float32Array.
                        #js [-1 -1 0, 1 -1 0, -1 1 0,
                             -1 1 0, 1 -1 0, 1 1 0])
              resize (fn [] (draw!))]
          (.bindBuffer gl (.-ARRAY_BUFFER gl) buffer)
          (.bufferData gl (.-ARRAY_BUFFER gl) vertices (.-STATIC_DRAW gl))

          (reset! renderer {:gl gl :program program :vs vs :fs fs
                            :position-loc position-loc
                            :resolution-loc resolution-loc
                            :time-loc time-loc
                            :buffer buffer
                            :elapsed 0 :running? false :last-time nil
                            :request nil :resize resize})
          (.addEventListener js/window "resize" resize)
          (draw!)))
      (catch :default error
        (stop!)
        (js/console.warn "Cloud background unavailable" error)))))
