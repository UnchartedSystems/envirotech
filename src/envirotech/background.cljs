(ns envirotech.background
  (:require ["twgl.js" :as twgl]))

(def vertex-shader
  "attribute vec4 position;
   void main() {
     gl_Position = position;
   }")

(def fragment-shader
  "#ifdef GL_FRAGMENT_PRECISION_HIGH
   precision highp float;
   #else
   precision mediump float;
   #endif
   uniform vec2 resolution;
   uniform float time;

   float hash(vec2 p) {
     return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
   }

   float noise(vec2 p) {
     vec2 cell = floor(p);
     vec2 f = fract(p);
     vec2 u = f * f * (3.0 - 2.0 * f);
     return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), u.x),
                mix(hash(cell + vec2(0.0, 1.0)),
                    hash(cell + vec2(1.0, 1.0)), u.x), u.y);
   }

   void main() {
     vec2 p = gl_FragCoord.xy / resolution.y * 3.0;
     p += vec2(time * 0.035, time * 0.012);
     float clouds = 0.0;
     float weight = 0.5;
     for (int i = 0; i < 4; i++) {
       clouds += weight * noise(p);
       p = p * 2.0 + vec2(17.0, 9.0);
       weight *= 0.5;
     }
     float coverage = smoothstep(0.35, 0.75, clouds);
     vec3 emerald = vec3(0.025, 0.32, 0.25);
     vec3 cloud = vec3(0.82, 0.91, 0.87);
     gl_FragColor = vec4(mix(emerald, cloud, coverage), 1.0);
   }")

;; Only renderer/clock bookkeeping persists; the shader has no frame history.
(defonce renderer (atom nil))

(defn- draw! []
  (when-let [{:keys [gl program buffers elapsed]} @renderer]
    (twgl/resizeCanvasToDisplaySize (.-canvas gl))
    (.viewport gl 0 0 (.-width (.-canvas gl)) (.-height (.-canvas gl)))
    (.useProgram gl (.-program program))
    (twgl/setBuffersAndAttributes gl program buffers)
    (twgl/setUniforms program
                      #js {:time elapsed
                           :resolution #js [(.-width (.-canvas gl))
                                            (.-height (.-canvas gl))]})
    (twgl/drawBufferInfo gl buffers)))

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
  (when-let [{:keys [gl program buffers request resize]} @renderer]
    (when request (js/cancelAnimationFrame request))
    (when resize (.removeEventListener js/window "resize" resize))
    (when buffers
      (doseq [attribute (array-seq (js/Object.values (.-attribs buffers)))]
        (.deleteBuffer gl (.-buffer attribute))))
    (when program
      (doseq [shader (array-seq (.getAttachedShaders gl (.-program program)))]
        (.deleteShader gl shader))
      (.deleteProgram gl (.-program program)))
    (reset! renderer nil)))

(defn init! []
  (stop!)
  (when-let [canvas (js/document.getElementById "background")]
    (try
      (when-let [gl (.getContext canvas "webgl")]
        (when-let [program (twgl/createProgramInfo gl #js [vertex-shader fragment-shader])]
          (reset! renderer {:gl gl :program program :elapsed 0
                            :running? false :last-time nil :request nil})
          (let [buffers (twgl/createBufferInfoFromArrays
                         gl #js {:position #js [-1 -1 0, 1 -1 0, -1 1 0,
                                                -1 1 0, 1 -1 0, 1 1 0]})
                resize (fn [] (draw!))]
            (swap! renderer assoc :buffers buffers :resize resize)
            (.addEventListener js/window "resize" resize)
            (draw!))))
      (catch :default error
        (stop!)
        (js/console.warn "Cloud background unavailable" error)))))
