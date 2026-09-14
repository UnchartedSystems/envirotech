#version 300 es
precision highp float;

out vec4 frag_color;

uniform float free_camera_zoom;
uniform vec3 free_camera_target;
uniform vec2 free_camera_orbit;
uniform float t;
uniform vec4 viewport;

mat2 rotation_2d(float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return mat2(c, s, -s, c);
}

float max_(vec2 v) {
  return max(v.x, v.y);
}

vec4 mod289(vec4 x) {
  return x - (floor(x * (1.0 / 289.0)) * 289.0);
}

vec4 permute(vec4 x) {
  return mod289(((x * 34.0) + 10.0) * x);
}

vec4 taylor_inv_sqrt(vec4 r) {
  return 1.79284291400159 - (0.85373472095314 * r);
}

vec2 fade(vec2 t) {
  return t * t * t * ((t * ((t * 6.0) - 15.0)) + 10.0);
}

float perlin(vec2 point) {
  vec4 Pi = floor(point.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(point.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod289(Pi);
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;
  vec4 i = permute(permute(ix) + iy);
  vec4 gx = (fract(i / 41.0) * 2.0) - 1.0;
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;
  vec2 g00 = vec2(gx.x, gy.x);
  vec2 g10 = vec2(gx.y, gy.y);
  vec2 g01 = vec2(gx.z, gy.z);
  vec2 g11 = vec2(gx.w, gy.w);
  vec4 norm = taylor_inv_sqrt(vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;
  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}

float terrain(vec2 pos) {
  return (((1.0 * perlin(pos)) + (0.25 * perlin((pos * 2.03) + vec2(8.1, 4.7)))) + (0.11 * perlin((pos * 4.09) + vec2(2.8, 13.2)))) + (0.04 * perlin((pos * 5.17) + vec2(16.4, 1.3)));
}

vec3 let_outer(float band) {
  {
    float u = clamp(smoothstep(0.0, 1.0, band), 0.0, 1.0);
    return (u < 0.5) ? mix(vec3(0.24, 0.34, 0.29), vec3(0.48, 0.55, 0.4), u * 2.0) : mix(vec3(0.48, 0.55, 0.4), vec3(0.78, 0.77, 0.6), (u * 2.0) - 1.0);
  }
}

vec4 let_outer1(vec2 Frag_Coord, vec2 resolution, float t) {
  {
    vec2 uv = Frag_Coord / max(resolution.x, resolution.y);
    vec2 pos = ((uv * 6.0) + vec2(t * 0.12, t * -0.08)) + vec2(1000.0, 1000.0);
    float elevation = (1.0 + terrain(pos)) / 2.05;
    float band = (elevation < 0.0) ? 0.0 : ((elevation < 0.1) ? 0.1 : ((elevation < 0.2) ? 0.2 : ((elevation < 0.3) ? 0.3 : ((elevation < 0.4) ? 0.4 : ((elevation < 0.5) ? 0.5 : ((elevation < 0.6) ? 0.6 : ((elevation < 0.7) ? 0.7 : ((elevation < 0.8) ? 0.8 : ((elevation < 0.9) ? 0.9 : ((elevation < 0.95) ? 0.95 : 1.0))))))))));
    vec3 result = let_outer(band);
    return vec4(result, 1.0);
  }
}

vec4 sample_(vec2 Frag_Coord, vec2 resolution, float t) {
  return let_outer1(Frag_Coord, resolution, t);
}

vec3 pow_(vec3 v, float e) {
  return pow(v, vec3(e));
}

void main() {
  const float gamma = 2.2;
  vec3 color = vec3(0.0, 0.0, 0.0);
  float alpha = 0.0;
  const uint aa_grid_size = 1u;
  const float aa_sample_width = 1.0 / float(1u + aa_grid_size);
  const vec2 pixel_origin = vec2(0.5, 0.5);
  vec2 local_frag_coord = gl_FragCoord.xy - viewport.xy;
  mat2 rotation = rotation_2d(0.2);
  for (uint y = 1u; y <= aa_grid_size; ++y) {
    for (uint x = 1u; x <= aa_grid_size; ++x) {
      vec2 sample_offset = (aa_sample_width * vec2(float(x), float(y))) - pixel_origin;
      sample_offset = rotation * sample_offset;
      sample_offset = fract(sample_offset + pixel_origin) - pixel_origin;
      {
        vec2 Frag_Coord = local_frag_coord + sample_offset;
        vec2 resolution = viewport.zw;
        vec2 frag_coord = ((Frag_Coord - (0.5 * resolution)) / max_(resolution)) * 2.0;
        vec4 this_sample = clamp(sample_(Frag_Coord, resolution, t), 0.0, 1.0);
        color += this_sample.rgb * this_sample.a;
        alpha += this_sample.a;
      }
    }
  }
  if (alpha > 0.0) {
    color = color / alpha;
    alpha /= float(aa_grid_size * aa_grid_size);
  }
  frag_color = vec4(pow_(color, 1.0 / gamma), alpha);
}
