# Abstract overhead relief with an elevation palette and printed halftone shading.
# Layered 2D noise supplies elevation without ray marching.
(def start-coords [1000 1000])
(def pan-speed-x 0.08)
(def pan-speed-y -0.06)
(def map-scale 5.0)

# Offset toward the light per band of height; larger offsets lengthen shadows.
(def shadow-offset [0.041 0.022])
(def shadow-height 0.07)
(def shadow-amount 0.28)

# Screen-space dots stay a consistent size as the terrain pans underneath.
(def halftone-spacing 6.0)
(def halftone-amount 0.32)
(def halftone-ink [0.08 0.12 0.15])

(def terrain-layers
  [{:impact 1.0 :scale .93 :offset [0.0 0.0]}
   {:impact 0.15 :scale 2.1 :offset [80.0 50.0]}
   {:impact 0.15 :scale 2.11 :offset [79.0 51.0]}
   {:impact 0.05 :scale 4.0 :offset [2.8 13.2]}
   {:impact 0.05 :scale 4.0 :offset [2.8 13.2]}
   {:impact 0.05 :scale 8.1 :offset [16.4 1.3]}])

(defn perlin-sum [pos layers]
  (var total 0.0)
  (var denominator 0.0)
  (each {:impact impact :scale scale :offset offset} layers
    (set total (+ total (* impact (perlin (+ (* pos scale) offset)))))
    (set denominator (+ denominator (math/abs impact))))
  (if (= denominator 0) 0.0 (/ total denominator)))

(gl/defn :float terrain [:vec2 pos]
  (return ,(perlin-sum pos terrain-layers)))

# (defn terrain-color [height]
#   (gl/let [valley (mix [0.07 0.20 0.26] [0.15 0.38 0.34]
#                        (smoothstep 0.10 0.28 height))
#            grass (mix valley [0.43 0.53 0.29] (smoothstep 0.28 0.45 height))
#            ochre (mix grass [0.77 0.63 0.34] (smoothstep 0.45 0.58 height))
#            clay (mix ochre [0.72 0.40 0.28] (smoothstep 0.58 0.72 height))]
#     (mix clay [0.94 0.88 0.70] (smoothstep 0.72 0.91 height))))

(defn terrain-color [height]
  (gl/let [grass (mix [0.25 0.28 0.14] [0.43 0.53 0.29] (smoothstep 0.10 0.5 height))
           ochre (mix grass [0.77 0.63 0.34] (smoothstep 0.5 0.7 height))]
    (mix ochre [0.86 0.75 0.39] (smoothstep 0.7 0.9 height))))

(defn halftone [color]
  (gl/let [grid (/ (vec2 (dot Frag-Coord [0.8660254 -0.5])
                          (dot Frag-Coord [0.5 0.8660254]))
                   halftone-spacing)
           cell (- (fract grid) 0.5)
           luminance (dot color [0.2126 0.7152 0.0722])
           radius (mix 0.10 0.38 (- 1.0 (clamp luminance 0 1)))
           edge (/ 0.75 halftone-spacing)
           dots (- 1.0 (smoothstep (- radius edge) (+ radius edge) (length cell)))]
    (mix color halftone-ink (* halftone-amount dots))))

(defn first-below [numbers value fallback]
  (var output fallback)
  (each number numbers
    (set output (gl/if (< value number) number output)))
  output)

(gl/defn :float terrain-band [:vec2 pos]
  (return ,(first-below [0.8 0.72 0.65 0.58 0.5 0.42 0.35 0.28 0.2 0.1]
                       (+ 0.5 (terrain pos)) 0.86)))

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
      
       result (* (terrain-color band) (- 1.0 (* shadow-amount shadow)))]
      
      (vec4 (halftone result) 1.0)))
