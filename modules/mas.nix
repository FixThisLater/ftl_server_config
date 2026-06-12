{ config, pkgs, ... }:
let
  masDataDir = "/var/lib/mas";
  masCli = "${pkgs.matrix-authentication-service}/bin/mas-cli";
in
{
  # User and group
  users.groups.mas = { };
  
  users.users.mas = {
    description = "Matrix Authentication Service";
    isSystemUser = true;
    group = "mas";
    home = masDataDir;
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
      WorkingDirectory = masDataDir;
      ExecStart = "${masCli} server --config ${config.sops.templates.mas-config.path}";
      Restart = "on-failure";
      RestartSec = "60s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ masDataDir ];
      CapabilityBoundingSet = "";
      SystemCallFilter = [ "@system-service" ];
      SystemCallErrorNumber = "EPERM";
    };
  };
}