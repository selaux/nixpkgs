{ system ? builtins.currentSystem,
  config ? {},
  pkgs ? import ../.. { inherit system config; }
}:

with import ../lib/testing.nix { inherit system pkgs; };
with pkgs.lib;

let
  publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDv70DY8I85MCUWatpuWtRYD5Vl0C4t8zold4ew4XtlsLYXqW9aa8Mz3bkNCqGICNyBae3lYdZLlj5vuUae7NPt/Ip6Bd3zScJGaqWlIbeytfT+XFFpAAkvN+gONywX5x6zBCjoZKxicIdXEw2zTTuBttVjd/uj6xZm0t3Ek8PaIe+XlmssrR3VEsyZTpx8iEgAGUvRLwRaK/b1FE56mwJCdLR2crZv6+ifVIJiiCC8Ax7ZOgAgAnz66pph8YDKf2rx+NmJEfEuYoOr3S0qgJQvmv/Z2YQgT63xP/c98eirVDNm2z1b2J2EF1PbV0RcG0bKgy1ySnmeOTmbzYtANiI5eS5KghSFI616HmDt8G/UG1VIRHEmDdR4mM94YoXB2fNqmYAoLbD/pXzFwgg00D5+FkDsH18PVECLZMQJn6DIxgNzhP5RKUxKb1x+9I6t/b7meC0VvziceOq8KXEIwu75sJYrwdqapTOET9rkttH7jwTs/IazcpX6xYU30o6dqROOP/qJCFdlGGB4Arf0XZdOTkyzlj4FFJK2cygxkDaCshX6MeLXNtaiRWpc8jlhGjmKxH8+C0oBXoV81a6ZxigUn0XjSkwdDqElUSa2sIHHsQClKXeZIZtAlSaKUsLnWo2HBBFsP/9m2kis3zYdMwrNnqSPuQMJ2x9/7CyeQheaYw== foobar";
  metadataDrive = pkgs.stdenv.mkDerivation {
    name = "metadata";
    buildCommand = ''
      mkdir -p $out/iso

      cat << EOF > $out/iso/user-data
      #cloud-config
      write_files:
      -   content: |
                cloudinit
          path: /tmp/cloudinit-write-file
      EOF

      cat << EOF > $out/iso/meta-data
      instance-id: iid-local01
      local-hostname: "test"
      public-keys:
          - "${publicKey}"
      EOF
      ${pkgs.cdrkit}/bin/genisoimage -volid cidata -joliet -rock -o $out/metadata.iso $out/iso
      '';
  };
in makeTest {
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ lewo ];
  };
  machine =
    { ... }:
    {
      virtualisation.qemu.options = [ "-cdrom" "${metadataDrive}/metadata.iso" ];
      services.cloud-init.enable = true;
    };
  testScript = ''
     $machine->start;
     $machine->waitForUnit("cloud-init.service");
     $machine->succeed("cat /tmp/cloudinit-write-file | grep -q 'cloudinit'");

     $machine->waitUntilSucceeds("cat /root/.ssh/authorized_keys | grep -q '${publicKey}'");
  '';
}
