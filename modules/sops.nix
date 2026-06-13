{ config, ... }:
let
  masUser = config.systemd.services.mas.serviceConfig.User;
  synapseUser = config.systemd.services.matrix-synapse.serviceConfig.User;
in
{ sops = {
  defaultSopsFile = ../secrets.yaml;
  secrets = {
    synapse-client-secret.owner = masUser;
    "mas/secret-mas" = {
      key = "mas/secret";
      owner = masUser;
    };
    "mas/secret-synapse" = {
      key = "mas/secret";
      owner = synapseUser;
    };
    "mas/enc-key".owner = masUser;
    "mas/rsa.pem".owner = masUser;
    "mas/ec-1.pem".owner = masUser;
    "mas/ec-2.pem".owner = masUser;
    "mas/ec-3.pem".owner = masUser;
  };
}; }