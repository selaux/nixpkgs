{ stdenv, lib, fetchurl, fetchFromGitHub, cmake, python, rustPlatform, SDL2, fltk, rapidjson, gtest, Carbon, Cocoa }:
let
  version = "0.18.0";
  src = fetchFromGitHub {
    owner = "ja2-stracciatella";
    repo = "ja2-stracciatella";
    rev = "v${version}";
    sha256 = "0r2gx1sh4c2sqvf2vws8dvk1zw1plw7dymysl0bfnilmfjwqxjcr";
  };
  editorSlf = fetchurl {
    url = "https://github.com/ja2-stracciatella/free-ja2-resources/releases/download/v1/editor.slf";
    sha256 = "09rgpxc1a6lg8g2gh9qv94y8mpak46bv90pz5zvzavbxfk5dshlm";
  };
  assets = stdenv.mkDerivation {
    pname = "ja2-stracciatella-assets";
    inherit src version;
    buildPhase = "true";
    installPhase = ''
      mkdir -p $out
      cp -R assets/externalized $out
      cp -R assets/mods $out
      cp -R assets/unittests $out
      cp ${editorSlf} $out/externalized/editor.slf
    '';
  };
  libstracciatella = rustPlatform.buildRustPackage {
    pname = "libstracciatella";
    inherit version;
    src = "${src}/rust";
    cargoSha256 = "08sm1xsv52zbr7fpbcpkh6z6bpqmwbj0319x5xm2wsph258jhx34";

    preBuild = ''
      mkdir -p $out/include/stracciatella
      export HEADER_LOCATION=$out/include/stracciatella/stracciatella.h
      export EXTRA_DATA_DIR=${assets}
    '';
  };
  stringTheoryUrl = "https://github.com/zrax/string_theory/archive/3.1.tar.gz";
  stringTheory = fetchurl {
    url = stringTheoryUrl;
    sha256 = "1flq26kkvx2m1yd38ldcq2k046yqw07jahms8a6614m924bmbv41";
  };
  luaUrl = "https://www.lua.org/ftp/lua-5.3.6.tar.gz";
  lua = fetchurl {
    url = luaUrl;
    sha256 = "0q3d8qhd7p0b7a4mh9g7fxqksqfs6mr1nav74vq26qvkp2dxcpzw";
  };
  solUrl = "https://github.com/ThePhD/sol2/archive/v3.2.2.zip";
  sol = fetchurl {
    url = solUrl;
    sha256 = "196kdfj9zkg5frrg0f4k5i84dlxhckzjbacp5klgyj8j2m0vyq50";
  };
  miniaudioUrl = "https://github.com/mackron/miniaudio/archive/634cdb028f340075ae8e8a1126620695688d2ac3.zip";
  miniaudio = fetchurl {
    url = miniaudioUrl;
    sha256 = "12ffgjqvgy9xh3ndys9b7gqpvacn3dhab8k1qwa781s6h70n7zfn";
  };
in
stdenv.mkDerivation {
  pname = "ja2-stracciatella";
  inherit src version;

  nativeBuildInputs = [ cmake python ];
  buildInputs = [ SDL2 fltk rapidjson gtest ] ++ lib.optionals stdenv.isDarwin [ Carbon Cocoa ];

  patches = [
    ./remove-rust-buildstep.patch
  ];

  preConfigure = ''
    # Use rust library built with nix
    substituteInPlace CMakeLists.txt \
      --replace lib/libstracciatella_c_api.a ${libstracciatella}/lib/libstracciatella_c_api.a \
      --replace include/stracciatella ${libstracciatella}/include/stracciatella \
      --replace bin/ja2-resource-pack ${libstracciatella}/bin/ja2-resource-pack

    # Patch dependencies that are usually loaded via url at build time
    substituteInPlace dependencies/lib-string_theory/builder/CMakeLists.txt.in \
      --replace ${stringTheoryUrl} file://${stringTheory}
    substituteInPlace dependencies/lib-lua/getter/CMakeLists.txt.in \
      --replace ${luaUrl} file://${lua}
    substituteInPlace dependencies/lib-sol2/getter/CMakeLists.txt.in \
      --replace ${solUrl} file://${sol}
    substituteInPlace dependencies/lib-miniaudio/getter/CMakeLists.txt.in \
      --replace ${miniaudioUrl} file://${miniaudio}

    cmakeFlagsArray+=("-DLOCAL_RAPIDJSON_LIB=OFF" "-DLOCAL_GTEST_LIB=OFF")
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    HOME=/tmp $out/bin/ja2 -unittests
  '';

  meta = {
    description = "Jagged Alliance 2, with community fixes";
    license = "SFI Source Code license agreement";
    homepage = "https://ja2-stracciatella.github.io/";
  };
}
