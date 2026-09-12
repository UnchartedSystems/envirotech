(set background-color
  (gl/let [s (frag-coord * 5 + [0 t])]
    (vec3 (perlin+ (s + (perlin+ (s + perlin+ (s - (sin t)))))))))
