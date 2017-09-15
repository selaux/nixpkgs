{ lib, buildPythonPackage, fetchPypi}:

buildPythonPackage rec {
  pname = "dogtail";
  name = "${pname}-${version}";
  version = "0.9.9";

  meta = {
    description = "dogtail is a GUI test tool and automation framework written in Python.";
    homepage = https://gitlab.com/dogtail/dogtail;
    license = lib.licenses.gpl2;
  };

  src = fetchPypi {
    inherit pname version;
    sha256 = "0p5wfssvzr9w0bvhllzbbd8fnp4cca2qxcpcsc33dchrmh5n552x";
  };

  buildInputs = [];
  propagatedBuildInputs = [];
}
