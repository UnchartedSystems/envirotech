# Abstract overhead relief with fine contour lines and a quiet sage palette.
# Eight 2D noise samples; one offset sample adds relief without ray marching.
(def pan-speed 0.012)
(def map-scale 3.0)
(def contour-count 12.0)

(gl/defn :float terrain [:vec2 pos]
  (return (+ (* 0.60 (perlin pos))
             (* 0.25 (perlin (+ (* pos 2.03) [8.1 4.7])))
             (* 0.11 (perlin (+ (* pos 4.09) [2.8 13.2])))
             (* 0.04 (perlin (+ (* pos 8.17) [16.4 1.3]))))))

(set background-color
  (gl/let [uv (/ (- Frag-Coord (* resolution 0.5)) resolution.y)
           pos (+ (* uv map-scale) [(* t pan-speed) (* t pan-speed -0.35)] [3.1 7.6])
           elevation (+ 0.5 (* 0.65 (terrain pos)))
           lowland (mix [0.24 0.34 0.29] [0.48 0.55 0.40]
                        (smoothstep 0.20 0.55 elevation))
           land (mix lowland [0.78 0.77 0.60] (smoothstep 0.52 0.80 elevation))
           neighbor (+ 0.5 (* 0.65 (terrain (+ pos [0.015 0.010]))))
           relief (clamp (+ 1.0 (* (- elevation neighbor) 7.0)) 0.72 1.18)
           level (* elevation contour-count)
           distance-to-line (abs (- (fract (+ level 0.5)) 0.5))
           # Conservative pixel footprint keeps contours soft on small screens.
           pixel-width (max 0.012 (/ (* map-scale contour-count 1.5) resolution.y))
           line (- 1.0 (smoothstep (* pixel-width 0.35) (* pixel-width 1.3) distance-to-line))
           shaded (* land relief)
           result (mix shaded (* shaded 0.72) (* line 0.65))]
    (vec4 result 1.0)))
