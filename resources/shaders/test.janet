(set background-color
     (gl/let [s ((Frag-Coord / (resolution.y / 2)) * 5 + [(t / 5) (t / 7)])
	      t (t / 5)]
	     (vec4 (perlin+ (s + (perlin+ (s + (perlin+ (s - (sin t))))))))))
