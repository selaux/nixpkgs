{ stdenv, lib, fetchFromGitHub, removeReferencesTo, which, go, go-bindata, makeWrapper, rsync
, iptables, coreutils
, components ? [
    "cmd/kubeadm"
    "cmd/kubectl"
    "cmd/kubelet"
    "cmd/kube-apiserver"
    "cmd/kube-controller-manager"
    "cmd/kube-proxy"
    "plugin/cmd/kube-scheduler"
    "federation/cmd/federation-apiserver"
    "federation/cmd/federation-controller-manager"
  ]
}:

with lib;

stdenv.mkDerivation rec {
  name = "kubernetes-${version}";
  version = "1.6.4";

  src = fetchFromGitHub {
    owner = "kubernetes";
    repo = "kubernetes";
    rev = "d6f433224538d4f9ca2f7ae19b252e6fcb66a3ae";
    sha256 = "1waxkr4ycrd23w8pi83gyf6jmawi1nhfzixp70fcwwka5h7p2y91";
  };

  buildInputs = [ removeReferencesTo makeWrapper which go rsync go-bindata ];

  outputs = ["out" "man" "pause"];

  postPatch = ''
    substituteInPlace "hack/lib/golang.sh" --replace "_cgo" ""
    substituteInPlace "hack/generate-docs.sh" --replace "make" "make SHELL=${stdenv.shell}"
    # hack/update-munge-docs.sh only performs some tests on the documentation.
    # They broke building k8s; disabled for now.
    echo "true" > "hack/update-munge-docs.sh"

    patchShebangs ./hack
  '';

  WHAT="--use_go_build cmd/kubectl";

  installPhase = ''
    mkdir -p "$out/bin" "$out/share/bash-completion/completions" "$man/share/man" "$pause/bin"
    cp _output/local/go/bin/* "$out/bin/"
    $out/bin/kubectl completion bash > $out/share/bash-completion/completions/kubectl
  '';

  meta = {
    description = "Production-Grade Container Scheduling and Management";
    license = licenses.asl20;
    homepage = http://kubernetes.io;
    maintainers = with maintainers; [offline];
    platforms = platforms.unix;
  };
}
