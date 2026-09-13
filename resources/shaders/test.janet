(set background-color
  (gl/let [s (frag-coord * 2 + [0 0])]
	  (vec3 (perlin+ (s + (perlin+ (s + perlin+ (s - (sin t)))))))))

(set background-color
     (gl/let [s frag-coord]
	     (vec3 (perlin+ (s * t)) (perlin+ (s * t)) (perlin+ (s / t)))))
