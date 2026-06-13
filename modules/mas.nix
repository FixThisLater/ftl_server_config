{ config, pkgs, ... }:
let
  dataDir = "/var/lib/mas";
  cli = "${pkgs.matrix-authentication-service}/bin/mas-cli";
  configFile = pkgs.writeText "mas-config.yaml" ''
    http:
      public_base: "https://mas.${config.networking.fqdn}"
      listeners:
        - name: web
          resources:
            - name: discovery
            - name: human
            - name: oauth
            - name: compat
            - name: graphql
              playground: true
            - name: assets
          binds: [address: "127.0.0.1:8081"]
        - name: internal
          resources:
            - name: health
            - name: adminapi
    #        - name: prometheus
          binds: [address: "127.0.0.1:8082"]

    database:
      uri: postgres:///mas?host=/run/postgresql

    matrix:
      homeserver: ${config.networking.fqdn}
      secret_file: /run/secrets/mas/secret-mas
      endpoint: http://127.0.0.1:8008

    secrets:
      encryption_file: /run/secrets/mas/enc-key
      keys:
        - kid: rsa
          key_file: /run/secrets/mas/rsa.pem
        - kid: ec-1
          key_file: /run/secrets/mas/ec-1.pem
        - kid: ec-2
          key_file: /run/secrets/mas/ec-2.pem
        - kid: ec-3
          key_file: /run/secrets/mas/ec-3.pem

    passwords:
      enabled: false

    upstream_oauth2:
      providers:
        - id: 01KTHCY8SQPGTM0G37HAZXPPSH
          issuer: https://auth.${config.networking.fqdn}/realms/main
          client_id: synapse
          client_secret_file: /run/secrets/synapse-client-secret
          token_endpoint_auth_method: client_secret_post
          claims_imports:
            skip_confirmation: true
            localpart:
              action: require
            displayname:
              action: force
            email:
              action: force
            account_name:
              action: force
  '';
in
{
  # User and group
  users.groups.mas = { };
  
  users.users.mas = {
    description = "Matrix Authentication Service";
    isSystemUser = true;
    group = "mas";
    home = dataDir;
    createHome = true;
  };

  # Systemd service
  systemd.services.mas = {
    description = "Matrix Authentication Service";
    after = [
      "network.target"
      "postgresql.service"
    ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "mas";
      Group = "mas";
      WorkingDirectory = dataDir;
      ExecStart = "${cli} server --config ${configFile}";
      Restart = "on-failure";
      RestartSec = "60s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ dataDir ];
      CapabilityBoundingSet = "";
      SystemCallFilter = [ "@system-service" ];
      SystemCallErrorNumber = "EPERM";
    };
  };
}