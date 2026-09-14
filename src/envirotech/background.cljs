(ns envirotech.background
  (:require [shadow.resource :as resource])
  (:require-macros [envirotech.bauble :refer [inline-bauble]]))

(def vertex-shader
  (resource/inline "shaders/vertex.glsl"))

(def background-spec
  (inline-bauble "mountains.janet"))

(def background-shader (:source background-spec))

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
  (let [vs (compile-shader gl (.-VERTEX_SHADER gl) vs-source)]
    (try
      (let [fs (compile-shader gl (.-FRAGMENT_SHADER gl) fs-source)]
        (try
          (let [program (.createProgram gl)]
            (try
              (.attachShader gl program vs)
              (.attachShader gl program fs)
              (.linkProgram gl program)
              (when-not (.getProgramParameter gl program (.-LINK_STATUS gl))
                (throw (js/Error. (str "Program link failed: " (.getProgramInfoLog gl program)))))
              (.detachShader gl program vs)
              (.detachShader gl program fs)
              program
              (catch :default error
                (.deleteProgram gl program)
                (throw error))))
          (finally (.deleteShader gl fs))))
      (finally (.deleteShader gl vs)))))

(defn- active-uniforms [gl program]
  (into {}
        (for [i (range (.getProgramParameter gl program (.-ACTIVE_UNIFORMS gl)))
              :let [info (.getActiveUniform gl program i)
                    name (.-name info)]]
          [name {:type (.-type info) :size (.-size info)
                 :location (.getUniformLocation gl program name)}])))

(defn- upload-uniform! [gl name {:keys [type size location]} value]
  (let [width (condp = type
                (.-FLOAT gl) 1
                (.-BOOL gl) 1
                (.-FLOAT_VEC2 gl) 2
                (.-FLOAT_VEC3 gl) 3
                (.-FLOAT_VEC4 gl) 4
                nil)
        values (if (sequential? value) value [value])]
    (when-not (and width (= size 1) (= width (count values))
                   (if (= type (.-BOOL gl))
                     (boolean? value)
                     (every? #(and (number? %) (js/Number.isFinite %)) values)))
      (throw (js/Error. (str "Invalid or unsupported Bauble uniform: " name))))
    (condp = type
      (.-BOOL gl) (.uniform1i gl location (if value 1 0))
      (.-FLOAT gl) (.uniform1f gl location (first values))
      (.-FLOAT_VEC2 gl) (.uniform2fv gl location (js/Float32Array. (clj->js values)))
      (.-FLOAT_VEC3 gl) (.uniform3fv gl location (js/Float32Array. (clj->js values)))
      (.-FLOAT_VEC4 gl) (.uniform4fv gl location (js/Float32Array. (clj->js values))))))

(defn- initialize-uniforms! [gl program uniforms defaults]
  (.useProgram gl program)
  (doseq [[name info] uniforms
          :when (not (contains? #{"t" "viewport"} name))]
    (let [value (cond
                  (contains? defaults name) (get defaults name)
                  (= name "free_camera_zoom") 1
                  (= name "free_camera_orbit") [0 0]
                  (= name "free_camera_target")
                  (if (= (:type info) (.-FLOAT_VEC2 gl)) [0 0] [0 0 0])
                  :else (throw (js/Error. (str "Missing Bauble uniform default: " name))))]
      (upload-uniform! gl name info value))))

(defn- resize-canvas-to-display-size! [canvas]
  (let [display-width (.-clientWidth canvas)
        display-height (.-clientHeight canvas)]
    (when (or (not= (.-width canvas) display-width)
              (not= (.-height canvas) display-height))
      (set! (.-width canvas) display-width)
      (set! (.-height canvas) display-height))))

(defn- draw! []
  (when-let [{:keys [gl program position-loc viewport-loc time-loc
                      buffer elapsed]} @renderer]
    (let [canvas (.-canvas gl)]
      (resize-canvas-to-display-size! canvas)
      (.viewport gl 0 0 (.-drawingBufferWidth gl) (.-drawingBufferHeight gl))
      (.useProgram gl program)

      (.bindBuffer gl (.-ARRAY_BUFFER gl) buffer)
      (.enableVertexAttribArray gl position-loc)
      (.vertexAttribPointer gl position-loc 3 (.-FLOAT gl) false 0 0)

      (.uniform4f gl viewport-loc 0 0 (.-drawingBufferWidth gl) (.-drawingBufferHeight gl))
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

(defn- dispose! [{:keys [gl program buffer request resize]}]
  (when request (js/cancelAnimationFrame request))
  (when resize (.removeEventListener js/window "resize" resize))
  (when buffer (.deleteBuffer gl buffer))
  (when program (.deleteProgram gl program)))

(defn stop! []
  (when-let [state @renderer]
    (dispose! state)
    (reset! renderer nil)))

(defn- prepare-renderer [gl]
  (let [program (link-program gl vertex-shader background-shader)
        buffer (.createBuffer gl)]
    (try
      (when-not buffer (throw (js/Error. "Could not allocate background buffer")))
      (initialize-uniforms! gl program (active-uniforms gl program) (:uniforms background-spec))
      (.bindBuffer gl (.-ARRAY_BUFFER gl) buffer)
      (.bufferData gl (.-ARRAY_BUFFER gl)
                   (js/Float32Array. #js [-1 -1 0, 1 -1 0, -1 1 0,
                                         -1 1 0, 1 -1 0, 1 1 0])
                   (.-STATIC_DRAW gl))
      {:gl gl :program program :buffer buffer
       :position-loc (.getAttribLocation gl program "position")
       :viewport-loc (.getUniformLocation gl program "viewport")
       :time-loc (.getUniformLocation gl program "t")
       :resize (fn [] (draw!))}
      (catch :default error
        (dispose! {:gl gl :program program :buffer buffer})
        (throw error)))))

(defn init! []
  (when-let [canvas (js/document.getElementById "background")]
    (try
      (let [gl (or (.getContext canvas "webgl2" #js {:antialias false :premultipliedAlpha false})
                   (throw (js/Error. "WebGL2 is unavailable")))
            prepared (prepare-renderer gl)
            {:keys [elapsed running?] :or {elapsed 0 running? false}} @renderer]
        ;; Keep the old renderer alive until the replacement is ready.
        (stop!)
        (reset! renderer (assoc prepared :elapsed elapsed :running? running?
                                :last-time nil :request nil))
        (.addEventListener js/window "resize" (:resize prepared))
        (draw!)
        (when running?
          (swap! renderer assoc :request (js/requestAnimationFrame frame!))))
      (catch :default error
        (js/console.warn "Background shader unavailable" error)))))
