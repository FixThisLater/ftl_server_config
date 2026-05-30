# These arguments, and only these, will vary by system; they're imported by the
# flake and inserted where applicable
rec {
  hostname = "fixthislater";
  domain = "com";
  fqdn = "${hostname}.${domain}";
  root_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6iC2Erg+IjdAGib4lzJ34HLICZ2NZqug1Wx8LSIt6Z admin@${fqdn}";
}