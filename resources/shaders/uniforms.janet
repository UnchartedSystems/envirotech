# The CLI exports GLSL without uniform defaults. Capture evaluated values using
# the same uniform/defuniform interface as Bauble, before the user's source runs.
(def envirotech-original-uniform uniform)
(var envirotech-uniform-count 0)
(defn envirotech-edn [value]
  (cond
    (number? value) (string value)
    (boolean? value) (if value "true" "false")
    (or (tuple? value) (array? value))
      (string "[" (string/join (map envirotech-edn value) " ") "]")
    (error "Unsupported Bauble uniform initial value")))
(defn uniform [value &opt name]
  (default name (string "_u" envirotech-uniform-count))
  (def result (envirotech-original-uniform value name))
  (set envirotech-uniform-count (+ envirotech-uniform-count 1))
  (print "// envirotech-default " (string/format "%q" name) " " (envirotech-edn value))
  result)
(defmacro defuniform [name value]
  ~(def ,name (,uniform ,value ,(string name))))
