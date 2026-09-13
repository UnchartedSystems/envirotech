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

vec3 mod289(vec3 x) {
  return x - (floor(x * (1.0 / 289.0)) * 289.0);
}

vec4 mod2891(vec4 x) {
  return x - (floor(x * (1.0 / 289.0)) * 289.0);
}

vec4 permute(vec4 x) {
  return mod2891(((x * 34.0) + 10.0) * x);
}

vec4 taylor_inv_sqrt(vec4 r) {
  return 1.79284291400159 - (0.85373472095314 * r);
}

vec3 fade(vec3 t) {
  return t * t * t * ((t * ((t * 6.0) - 15.0)) + 10.0);
}

float perlin(vec3 point) {
  vec3 Pi0 = floor(point);
  vec3 Pi1 = Pi0 + 1.0;
  vec3 Pi01 = mod289(Pi0);
  vec3 Pi11 = mod289(Pi1);
  vec3 Pf0 = fract(point);
  vec3 Pf1 = Pf0 - 1.0;
  vec4 ix = vec4(Pi01.x, Pi11.x, Pi01.x, Pi11.x);
  vec4 iy = vec4(Pi01.yy, Pi11.yy);
  vec4 iz0 = Pi01.zzzz;
  vec4 iz1 = Pi11.zzzz;
  vec4 ixy = permute(permute(ix) + iy);
  vec4 ixy0 = permute(ixy + iz0);
  vec4 ixy1 = permute(ixy + iz1);
  vec4 gx0 = ixy0 * (1.0 / 7.0);
  vec4 gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
  gx0 = fract(gx0);
  vec4 gz0 = 0.5 - abs(gx0) - abs(gy0);
  vec4 sz0 = step(gz0, vec4(0.0));
  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
  gy0 -= sz0 * (step(0.0, gy0) - 0.5);
  vec4 gx1 = ixy1 * (1.0 / 7.0);
  vec4 gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
  gx1 = fract(gx1);
  vec4 gz1 = 0.5 - abs(gx1) - abs(gy1);
  vec4 sz1 = step(gz1, vec4(0.0));
  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
  gy1 -= sz1 * (step(0.0, gy1) - 0.5);
  vec3 g000 = vec3(gx0.x, gy0.x, gz0.x);
  vec3 g100 = vec3(gx0.y, gy0.y, gz0.y);
  vec3 g010 = vec3(gx0.z, gy0.z, gz0.z);
  vec3 g110 = vec3(gx0.w, gy0.w, gz0.w);
  vec3 g001 = vec3(gx1.x, gy1.x, gz1.x);
  vec3 g101 = vec3(gx1.y, gy1.y, gz1.y);
  vec3 g011 = vec3(gx1.z, gy1.z, gz1.z);
  vec3 g111 = vec3(gx1.w, gy1.w, gz1.w);
  vec4 norm0 = taylor_inv_sqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  vec4 norm1 = taylor_inv_sqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;
  float n000 = dot(g000, Pf0);
  float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
  float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
  float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
  float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
  float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
  float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
  float n111 = dot(g111, Pf1);
  vec3 fade_xyz = fade(Pf0);
  vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
  vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
  float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
  return 2.2 * n_xyz;
}

float cloud_noise(vec3 pos) {
  return (((0.62 * perlin(pos)) + (0.25 * perlin((pos * 2.03) + vec3(13.1, 7.2, 9.4)))) + (0.09 * perlin((pos * 4.11) + vec3(3.7, 19.2, 5.1)))) + (0.04 * perlin((pos * 8.23) + vec3(11.2, 2.8, 15.3)));
}

float cloud_density(vec3 pos, float coverage) {
  float envelope = smoothstep(0.0, 0.16, pos.y) * (1.0 - smoothstep(0.42, 1.0, pos.y));
  float body = cloud_noise(pos * vec3(1.0, 1.65, 1.0));
  return envelope * smoothstep(coverage, coverage + 0.16, body);
}

vec4 cloud_deck(vec3 direction, float altitude, float thickness, vec2 wind, float coverage, vec3 haze, uint steps) {
  float step_length = thickness / (direction.y * float(steps));
  vec3 accumulated = vec3(0.0);
  float transmission = 1.0;
  for (uint i = 0u; i < steps; ++i) {
    float h = (float(i) + 0.5) / float(steps);
    float distance = (altitude + (h * thickness)) / direction.y;
    vec3 world = (direction * distance) + vec3(wind.x, 0.0, wind.y);
    vec3 sample_pos = vec3(world.x, h, world.z);
    float density = cloud_density(sample_pos, coverage);
    if (density > 0.005) {
      float sun_density = cloud_density(sample_pos + vec3(0.22, 0.18, -0.12), coverage);
      float sunlight = exp(-3.0 * sun_density);
      vec3 ambient = mix(vec3(0.43, 0.53, 0.66), vec3(0.72, 0.79, 0.86), h);
      vec3 lit = (ambient * 0.65) + (vec3(0.55, 0.51, 0.43) * sunlight);
      vec3 faded = mix(lit, haze, smoothstep(5.0, 18.0, distance));
      float alpha = 1.0 - exp((-7.0 * density) * step_length);
      accumulated += (transmission * alpha) * faded;
      transmission *= 1.0 - alpha;
    }
    if (transmission < 0.015) break;
  }
  return vec4(accumulated, 1.0 - transmission);
}

vec4 let_outer(vec2 Frag_Coord, vec2 resolution, float t) {
  {
    vec2 uv = (Frag_Coord - (resolution * 0.5)) / resolution.y;
    vec3 direction = normalize(vec3(uv.x, uv.y + 0.9, 1.15));
    float clock = t * 0.018;
    vec3 sky_color = mix(vec3(0.58, 0.74, 0.86), vec3(0.09, 0.3, 0.56), smoothstep(0.0, 0.8, direction.y));
    float sun = pow(max(0.0, dot(direction, normalize(vec3(0.55, 0.65, 1.0)))), 12.0);
    vec3 sunlit_sky = sky_color + (vec3(0.1, 0.075, 0.035) * sun);
    vec4 distant = cloud_deck(direction, 3.8, 0.55, vec2((clock * -0.45) + 17.0, 9.0), 0.165, sky_color, 24u);
    vec4 near = cloud_deck(direction, 1.5, 1.0, vec2((clock * -1.0) + 2.0, 3.0), 0.14, sky_color, 32u);
    vec3 behind = distant.rgb + (sunlit_sky * (1.0 - distant.a));
    vec3 result = near.rgb + (behind * (1.0 - near.a));
    return vec4(result, 1.0);
  }
}

vec4 sample_(vec2 Frag_Coord, vec2 resolution, float t) {
  return let_outer(Frag_Coord, resolution, t);
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
