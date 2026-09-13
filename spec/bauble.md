# Bauble shader inputs

The background renderer supplies `t` in seconds and `viewport` in drawing-buffer
pixels. Free-camera defaults are zoom `1`, target at the origin, and orbit `[0 0]`.
The target upload follows the linked shader's type: `vec2` for 2D or `vec3` for 3D.
Camera controls are fixed; they do not respond to pointer input.

Custom defaults work directly in Janet:

```janet
(defuniform radius (* 25 4))
(defuniform tint [1 0.5 0.25])
(ball radius | color tint)
```

The compile hook prepends `resources/shaders/uniforms.janet`, which wraps Bauble's
`uniform` and `defuniform` to record evaluated initial values. Those values travel
with the GLSL as comments, so a failed compilation retains both the previous shader
and its defaults. Both named and anonymous uniforms are supported. The renderer
initializes active float, bool, vec2, vec3, and vec4 uniforms after linking, and skips
uniforms optimized out by WebGL. Invalid values, unsupported types, or missing
defaults reject the new renderer and keep the previous one available.

`inline-bauble` returns `{:source glsl :uniforms {glsl-name initial-value}}`.
Defaults are reapplied whenever the shader reloads. The `t` and `viewport` names
are reserved for the renderer; use other names for custom inputs. No runtime
custom-uniform control API is provided.

Regression checks:

```sh
clojure -M:test -e "(require 'envirotech.bauble-test)(let [r (clojure.test/run-tests 'envirotech.bauble-test)] (System/exit (+ (:fail r) (:error r))))"
clojure -M:test -m shadow.cljs.devtools.cli compile uniform-test
```

The first check invokes the installed Bauble compiler; the second checks WebGL
upload selection with a mock context in Node. Neither is a visual browser test.
