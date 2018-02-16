{ stdenv, fetchurl, openfortivpn, automake, autoconf, libtool, intltool, pkgconfig,
networkmanager, ppp, lib, libsecret, withGnome ? true, gnome3, procps, kmod, autoreconfHook }:

stdenv.mkDerivation rec {
  name    = "${pname}${if withGnome then "-gnome" else ""}-${version}";
  pname   = "NetworkManager-fortisslvpn";
  major   = "1.2";
  version = "${major}.8";

  src = fetchurl {
    url    = "mirror://gnome/sources/${pname}/${major}/${pname}-${version}.tar.xz";
    sha256 = "01gvdv9dknvzx05plq863jh1xz1v8vgj5w7v9fmw5v601ggybf4w";
  };

  buildInputs = [ openfortivpn networkmanager ppp libtool libsecret ]
    ++ stdenv.lib.optionals withGnome [ gnome3.gtk gnome3.libgnome_keyring gnome3.gconf gnome3.networkmanagerapplet ];

  nativeBuildInputs = [ autoreconfHook automake autoconf intltool pkgconfig ];

  configureFlags = [
    "${if withGnome then "--with-gnome" else "--without-gnome"}"
    "--disable-static"
    "--localstatedir=/var"
  ];

  patches = [ ./fortissl_dont_create_state_dir.patch ];

  preConfigure = ''
     substituteInPlace "src/nm-fortisslvpn-service.c" \
       --replace "/bin/openfortivpn" "${openfortivpn}/bin/openfortivpn"
  '';

  meta = {
    description = "NetworkManager's FortiSSL plugin";
    inherit (networkmanager.meta) maintainers platforms;
  };
}

