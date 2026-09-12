#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
uniform vec2 resolution;
uniform float time;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
  vec2 cell = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), u.x),
	     mix(hash(cell + vec2(0.0, 1.0)),
		 hash(cell + vec2(1.0, 1.0)), u.x), u.y);
}

void main() {
  vec2 p = gl_FragCoord.xy / resolution.y;
  
  gl_FragColor = vec4(p.x,0.0,0.0,1.0);
}

// void main() {
//   // Broad banks with four layers; finer layers contribute less detail.
//   vec2 p = gl_FragCoord.xy / resolution.y * 2.1;
//   vec2 drift = time * vec2(0.088, 0.046);
//   float clouds = 0.0;
//   float weight = 0.50;
//   for (int i = 0; i < 6; i++) {
//     clouds += weight * noise(p + drift);
//     p = p * 2.0 + vec2(17.0, 9.0);
//     // Scale drift slightly less than frequency so layers move independently.
//     drift *= 1.2;
//     weight *= 0.5;
//   }
//   float coverage = smoothstep(0.38, 0.78, clouds);
//   float highlights = smoothstep(0.65, 1.0, coverage);
//   vec3 emerald = vec3(0.025, 0.32, 0.25);
//   vec3 mist = vec3(0.29, 0.53, 0.43);
//   vec3 cloud = vec3(0.85, 0.90, 0.82);
//   vec3 color = mix(emerald, mist, coverage);
//   gl_FragColor = vec4(mix(color, cloud, highlights), 1.0);
// }
