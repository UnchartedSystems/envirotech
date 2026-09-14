# Minimal clouds seen from above. Coherent banks drift across a muted blue field.
# Six 2D noise samples per pixel; no volume integration, geometry, or boiling.
(def pan-speed 0.028)
(def cloud-scale 3.8)
(def cloud-threshold 0.035)

(gl/defn :float cloud-field [:vec2 pos]
  (return (+ (* 0.72 (perlin pos))
             (* 0.21 (perlin (+ (* pos 2.1) [9.2 3.1])))
             (* 0.07 (perlin (+ (* pos 4.2) [1.7 15.3]))))))

(set background-color
  (gl/let [uv (/ (- Frag-Coord (* resolution 0.5)) resolution.y)
           pos (+ (* uv cloud-scale) [(* t pan-speed) (* t pan-speed 0.18)] [4.2 9.7])
           field (cloud-field pos)
           shifted (cloud-field (+ pos [0.11 -0.09]))
           cover (smoothstep cloud-threshold (+ cloud-threshold 0.14) field)
           shadow (smoothstep cloud-threshold (+ cloud-threshold 0.17) shifted)
           blue (mix [0.32 0.51 0.64] [0.25 0.41 0.54] (* shadow 0.3))
           light (clamp (+ 0.68 (* (- field shifted) 2.2)) 0.0 1.0)
           body (mix [0.68 0.75 0.79] [0.96 0.97 0.95] light)
           result (mix blue body cover)]
    (vec4 result 1.0)))
