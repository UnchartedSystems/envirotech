# Overhead swells: two crossing wave trains with sparse pale crest highlights.
# Two 2D noise samples, analytic lighting; no geometry or reflection marching.
(def wave-speed 0.22)
(def ocean-scale 5.0)

(set background-color
  (gl/let [uv (/ (- Frag-Coord (* resolution 0.5)) resolution.y)
           pos (+ (* uv ocean-scale) [(* t 0.012) (* t 0.005)])
           warp (perlin (* pos 0.65))
           detail (perlin (+ (* pos 1.6) [7.8 2.3]))
           phase (+ (* pos.x 3.0) (* pos.y 5.0) (* warp 2.0) (* t (- wave-speed)))
           cross-phase (+ (* pos.x -5.0) (* pos.y 2.4) (* detail 0.7) (* t -0.15))
           swell (+ (* 0.76 (sin phase)) (* 0.24 (sin cross-phase)))
           slope (+ (* 0.76 (cos phase)) (* 0.24 (cos cross-phase)))
           depth (mix [0.035 0.16 0.20] [0.085 0.31 0.35] (* 0.5 (+ swell 1.0)))
           sheen (* 0.11 (pow (max 0.0 slope) 6.0))
           crest (* (smoothstep 0.75 0.98 swell) (smoothstep -0.15 0.35 detail))
           water (+ depth (* [0.44 0.66 0.68] sheen))
           result (mix water [0.55 0.73 0.72] (* crest 0.36))]
    (vec4 result 1.0)))
