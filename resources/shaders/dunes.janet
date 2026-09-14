# Overhead sand: broad asymmetric slip faces, sparse wind ripples, slow panning.
# Color only: two 2D noise samples per pixel, no geometry or ray marching.
(def pan-speed 0.018)
(def dune-scale 5.5)

(set background-color
  (gl/let [uv (/ (- Frag-Coord (* resolution 0.5)) resolution.y)
           pos (+ (* uv dune-scale) [(* t pan-speed) (* t pan-speed 0.3)])
           bend (perlin (* pos 0.45))
           detail (perlin (+ (* pos 1.2) [8.3 2.7]))
           phase (+ (* pos.x 3.8) (* pos.y 1.1) (* bend 3.0) (* detail 0.22))
           ridge (sin phase)
           face (smoothstep -0.25 0.65 (cos phase))
           sand (mix [0.48 0.30 0.16] [0.83 0.66 0.43] face)
           crest (pow (* 0.5 (+ ridge 1.0)) 18.0)
           ripples (* 0.012 (sin (+ (* phase 15.0) (* detail 2.0)))
                      (smoothstep -0.3 0.6 ridge))
           result (+ sand (* [0.09 0.075 0.05] crest) ripples)]
    (vec4 result 1.0)))
