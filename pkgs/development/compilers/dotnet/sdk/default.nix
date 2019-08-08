{ stdenv
, fetchurl
, libunwind
, openssl
, icu
, libuuid
, zlib
, curl
, makeWrapper
}:
let
  rpath = stdenv.lib.makeLibraryPath [ stdenv.cc.cc libunwind libuuid icu openssl zlib curl ];
in
  stdenv.mkDerivation rec {
    version = "2.2.401";
    netCoreVersion = "2.2.6";
    pname = "dotnet-sdk";

    buildInputs = [ makeWrapper ];

    src = fetchurl {
      url = "https://dotnetcli.azureedge.net/dotnet/Sdk/${version}/dotnet-sdk-${version}-osx-x64.tar.gz";
      sha512 = "1lf1izr2ig524cvid969698rs7dv2r8540a73810f4a8d143i1c2fk57mb5dy28xr5vl1dshhmpj61507asnkb2lp3vw5dm8zxwcpwh";
    };

    sourceRoot = ".";

    buildPhase = ''
      runHook preBuild
    '' + stdenv.lib.optionalString (!stdenv.isDarwin) ''
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" ./dotnet
      patchelf --set-rpath "${rpath}" ./dotnet
    '' + ''
      find -type f -name "*.so" -exec patchelf --set-rpath "${rpath}" {} \;
      echo -n "dotnet-sdk version: "
      ./dotnet --version
      runHook postBuild
    '';

    dontPatchELF = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp -r ./ $out
      ln -s $out/dotnet $out/bin/dotnet
      runHook postInstall
    '' + stdenv.lib.optionalString stdenv.isDarwin ''
        wrapProgram $out/bin/dotnet --set DOTNET_SKIP_FIRST_TIME_EXPERIENCE true
    '';

    meta = with stdenv.lib; {
      homepage = https://dotnet.github.io/;
      description = ".NET Core SDK ${version} with .NET Core ${netCoreVersion}";
      platforms = stdenv.lib.platforms.unix;
      maintainers = with maintainers; [ kuznero ];
      license = licenses.mit;
    };
  }
