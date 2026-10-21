{ python3Packages }:

python3Packages.buildPythonPackage {
  pname = "bf";
  version = "0";
  pyproject = true;
  src = ./.;
  build-system = [ python3Packages.setuptools ];
  meta.mainProgram = "bf";
}
