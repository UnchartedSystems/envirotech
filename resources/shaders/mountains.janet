# Abstract overhead relief with fine contour lines and a quiet sage palette.
# Eight 2D noise samples; one offset sample adds relief without ray marching.
(def start-coords [1000 1000])
(def pan-speed-x 0.12)
(def pan-speed-y -0.08)
(def map-scale 6.0)

(def color-baseline? 0.5) #What is this?
(def height-multi 0.65)

(def shade-offset [0.055 0.010])
(def shade-amount? 0.42)
(def shademap-min 0.7)
(def shademap-max 1.2)

(def contour-count 11.0)

# How does this work?
(gl/defn
 :float terrain [:vec2 pos]
 (return (+ (* 1.0 (perlin pos))
	    (* 0.25 (perlin (+ (* pos 2.03) [8.1 4.7])))
	    #_(* 0.09 (perlin (+ (* pos 13.0) [2.8 13.2])))
	    (* 0.11 (perlin (+ (* pos 4.09) [2.8 13.2])))
	    (* 0.04 (perlin (+ (* pos 5.17) [16.4 1.3]))))))



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

(set background-color
     (gl/let
      [uv (/ Frag-Coord (max resolution.x resolution.y))
       pos (+ (* uv map-scale) [(* t pan-speed-x) (* t pan-speed-y)] start-coords)
       elevation (/ (+ 1 (terrain pos)) 2.05)

       band (first-below [0.95 0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.1 0.0] elevation 1)
       
       result (mix3 [0.24 0.34 0.29] [0.48 0.55 0.40] [0.78 0.77 0.60] (smoothstep 0 1 band))]
      
      (vec4 result 1.0)))
