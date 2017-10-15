{ stdenv, fetchurl, makeWrapper }:
let
  allSrcs = {
    "i686-linux" = {
      system = "linux32";
      sha256 = "0ilr8lz5gmhm45mvay3rrwlv317dasglf37ilsjgld44qpy42jiv";
    };

    "x86_64-linux" = {
      system = "linux64";
      sha256 = "0yfsdrgkxzd1zl5algqz9sx7cz5ch5h6ir4sh92lb3m2hb6vk4qw";
    };

    "x86_64-darwin" = {
      system = "macos";
      sha256 = "0hpmpzscqxjbwd9sii1f1nwx7xx5wb3rzv15cfdi731ircvxvhxh";
    };
  };
  systemSrc = allSrcs."${stdenv.system}"
    or (throw "missing geckodriver binary for ${stdenv.system}");
in
stdenv.mkDerivation rec {
  name = "geckodriver-${version}";
  version = "0.19.0";

  src = fetchurl {
    url = "https://github.com/mozilla/geckodriver/releases/download/v${version}/geckodriver-v${version}-${systemSrc.system}.tar.gz";
    sha256 = systemSrc.sha256;
  };

  nativeBuildInputs = [];

  setSourceRoot = "sourceRoot=`pwd`";

  installPhase = ''
    install -m755 -D geckodriver $out/bin/geckodriver
  '';

  meta = with stdenv.lib; {
    homepage = https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver;
    description = "Proxy for using W3C WebDriver-compatible clients to interact with Gecko-based browsers.";
    license = [ "MPL-2.0" ];
    platforms = attrNames allSrcs;
  };
}
