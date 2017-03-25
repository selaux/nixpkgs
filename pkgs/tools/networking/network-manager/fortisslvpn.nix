{ stdenv, fetchurl, openfortivpn, ppp, intltool, pkgconfig, networkmanager, libsecret
, withGnome ? true, gnome3 }:

stdenv.mkDerivation rec {
  name    = "${pname}${if withGnome then "-gnome" else ""}-${version}";
  pname   = "NetworkManager-fortisslvpn";
  major   = "1.2";
  version = "${major}.4";

  src = fetchurl {
    url    = "mirror://gnome/sources/${pname}/${major}/${pname}-${version}.tar.xz";
    sha256 = "0wsbj5lvf9l1w8k5nmaqnzmldilh482bn4z4k8a3wnm62xfxgscr";
  };

  buildInputs = [ networkmanager ppp libsecret ]
    ++ stdenv.lib.optionals withGnome [ gnome3.gtk gnome3.libgnome_keyring
                                        gnome3.networkmanagerapplet ];

  nativeBuildInputs = [ intltool pkgconfig ];

  configureFlags = [
    "${if withGnome then "--with-gnome --with-gtkver=3" else "--without-gnome"}"
  ];

  preConfigure = ''
     substituteInPlace "src/nm-fortisslvpn-service.c" \
       --replace "/bin/openfortivpn" "${openfortivpn}/bin/openfortivpn"
  '';

  meta = {
    description = "NetworkManager's FortiSSL plugin";
    inherit (networkmanager.meta) maintainers platforms;
  };
}
