# Abstract overhead relief with fine contour lines and a quiet sage palette.
# Layered 2D noise supplies elevation without ray marching.
(def start-coords [1000 1000])
(def pan-speed-x 0.12)
(def pan-speed-y -0.08)
(def map-scale 5.0)

# Offset toward the light per band of height; larger offsets lengthen shadows.
(def shadow-offset [0.055 0.010])
(def shadow-height 0.07)
(def shadow-amount 0.28)

(def contour-count 11.0)

(def terrain-layers
  [{:impact 1.0 :scale .93 :offset [0.0 0.0]}
   #{:impact 0.40 :scale 1.2 :offset [10.0 -7.0]}
   {:impact 0.15 :scale 2.1 :offset [80.0 50.0]}
   {:impact 0.15 :scale 2.11 :offset [79.0 51.0]}
   {:impact 0.05 :scale 4.0 :offset [2.8 13.2]}
   {:impact 0.05 :scale 4.0 :offset [2.8 13.2]}
   {:impact 0.05 :scale 8.1 :offset [16.4 1.3]}])

(def terrain-layersx
  [{:impact 1.0 :scale 1.0 :offset [0.0 0.0]}])

(defn perlin-sum [pos layers]
  # Perlin is bounded by [-1, 1]. Absolute impacts preserve that bound even
  # with negative weights, but the combined noise need not reach either end.
  (var total 0.0)
  (var denominator 0.0)
  (each {:impact impact :scale scale :offset offset} layers
    (set total (+ total (* impact (perlin (+ (* pos scale) offset)))))
    (set denominator (+ denominator (math/abs impact))))
  (if (= denominator 0) 0.0 (/ total denominator)))

(gl/defn :float terrain [:vec2 pos]
  (return ,(perlin-sum pos terrain-layers)))

(defn mix3 [a b c amount]
  (gl/let [u (clamp amount 0 1)]
    (gl/if (< u 0.5)
      (mix a b (* u 2))
      (mix b c (- (* u 2) 1)))))

(defn first-below [numbers value fallback]
  (var output fallback)
  (each number numbers
    (set output (gl/if (< value number) number output)))
  output)

(gl/defn :float terrain-band [:vec2 pos]
  (return ,(first-below [0.8 0.72 0.65 0.58 0.5 0.42 0.35 0.28 0.2 0.1 0.0]
                       (+ 0.5 (terrain pos)) 0.91)))

(defn band-shadow [pos band]
  # Three fixed lightward probes approximate the stepped terrain silhouette.
  # Compare against a rising light ray so taller bands cast farther. Combining
  # with max keeps overlapping shadows flat instead of darkening them again.
  (var shadow 0.0)
  (each distance [0.5 1.5 3.0]
    (set shadow
         (max shadow
              (step (+ band (* distance shadow-height))
                    (terrain-band (+ pos (* shadow-offset distance)))))))
  shadow)

(set background-color
     (gl/let
      [uv (/ Frag-Coord (max resolution.x resolution.y))
       pos (+ (* uv map-scale) [(* t pan-speed-x) (* t pan-speed-y)] start-coords)
       band (terrain-band pos)
       shadow (band-shadow pos band)
      
       result (mix3 [0.21 0.30 0.26] [0.42 0.48 0.34] [0.70 0.74 0.62] (smoothstep 0.1 1.0 band))]
      
      (vec4 (* result (- 1.0 (* shadow-amount shadow))) 1.0)))
