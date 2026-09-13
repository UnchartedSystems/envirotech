#(set background-color (vec4 1.0 1.0 1.0 0.0))

# (set background-color
#      (gl/let [s ((Frag-Coord / (resolution.y / 2)) * 5 + [(t / 5) (t / 7)])
# 	      t (t / 5)]
# 	     (vec4 (perlin+ (s + (perlin+ (s + (perlin+ (s - (sin t))))))))))

# all detail travels with its parent cloud instead of boiling.
(def cloud-speed 0.018)
# higher thresholds leave more open blue sky.
(def cloud-coverage 0.14)

# layers of a cloud
(gl/defn :float cloud-noise [:vec3 pos]
  (return (+ (* 0.62 (perlin pos))
             (* 0.25 (perlin (+ (* pos 2.03) [13.1 7.2 9.4])))
             (* 0.09 (perlin (+ (* pos 4.11) [3.7 19.2 5.1])))
             (* 0.04 (perlin (+ (* pos 8.23) [11.2 2.8 15.3]))))))

# A shallow base and rounded upper envelope give the clouds a common altitude.
(gl/defn :float cloud-density [:vec3 pos :float coverage]
  (var envelope (* (smoothstep 0.0 0.16 pos.y)
                   (- 1.0 (smoothstep 0.42 1.0 pos.y))))
  (var body (cloud-noise (* pos [1.0 1.65 1.0])))
  (return (* envelope (smoothstep coverage (+ coverage 0.16) body))))

# Integrate through a cloud deck front to back. Opacity comes from thickness,
# leaving clear sky between solid banks rather than overlaying translucent noise.
(gl/defn :vec4 cloud-deck
  [:vec3 direction :float altitude :float thickness :vec2 wind
   :float coverage :vec3 haze :uint steps]
  (var step-length (/ thickness (* direction.y (float steps))))
  (var accumulated (vec3 0.0))
  (var transmission 1.0)
  (for (var i 0:u) (< i steps) (++ i)
    (var h (/ (+ (float i) 0.5) (float steps)))
    (var distance (/ (+ altitude (* h thickness)) direction.y))
    (var world (+ (* direction distance) (vec3 wind.x 0.0 wind.y)))
    (var sample-pos (vec3 world.x h world.z))
    (var density (cloud-density sample-pos coverage))
    (if (> density 0.005) (do
      (var sun-density (cloud-density (+ sample-pos [0.22 0.18 -0.12]) coverage))
      (var sunlight (exp (* -3.0 sun-density)))
      (var ambient (mix [0.43 0.53 0.66] [0.72 0.79 0.86] h))
      (var lit (+ (* ambient 0.65) (* [0.55 0.51 0.43] sunlight)))
      (var faded (mix lit haze (smoothstep 5.0 18.0 distance)))
      (var alpha (- 1.0 (exp (* -7.0 density step-length))))
      (+= accumulated (* transmission alpha faded))
      (*= transmission (- 1.0 alpha))))
    (if (< transmission 0.015) (break)))
  (return (vec4 accumulated (- 1.0 transmission))))

(set background-color
  (gl/let [uv (/ (- Frag-Coord (* resolution 0.5)) resolution.y)
           direction (normalize (vec3 uv.x (uv.y + 0.90) 1.15))
           clock (t * cloud-speed)
           sky-color (mix [0.58 0.74 0.86] [0.09 0.30 0.56]
                          (smoothstep 0.0 0.8 direction.y))
           sun (pow (max 0.0 (dot direction (normalize [0.55 0.65 1.0]))) 12.0)
           sunlit-sky (+ sky-color (* [0.10 0.075 0.035] sun))
           # A higher, thinner deck recedes behind the main cumulus banks.
           distant (cloud-deck direction 3.8 0.55
                                [(clock * -0.45 + 17.0) 9.0]
                                (cloud-coverage + 0.025) sky-color 24:u)
           near (cloud-deck direction 1.5 1.0
                             [(clock * -1.0 + 2.0) 3.0]
                             cloud-coverage sky-color 32:u)
           behind (+ distant.rgb (* sunlit-sky (- 1.0 distant.a)))
           result (+ near.rgb (* behind (- 1.0 near.a)))]
    (vec4 result 1.0)))
