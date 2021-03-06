let
  fetch = jsonFile:
    with builtins;
    let spec = fromJSON (readFile jsonFile);
    in fetchTarball { inherit (spec) sha256; url = "${spec.url}/archive/${spec.rev}.tar.gz"; };
in import (fetch ./github.json)
