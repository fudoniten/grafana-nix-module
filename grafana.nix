{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.fudo.services.grafana;

  datasourceOpts = { name, ... }: {
    options = with types; {
      url = mkOption {
        type = str;
        description = "Datasource URL.";
      };

      type = mkOption {
        type = enum [ "prometheus" "loki" ];
        description = "Datasource type.";
        default = "prometheus";
      };

      name = mkOption {
        type = str;
        default = name;
      };

      default =
        mkEnableOption "Use this datasource as the default while querying.";
    };
  };

in {
  options.fudo.services.grafana = with types; {
    enable = mkEnableOption "Enable Grafana server.";

    state-directory = mkOption {
      type = str;
      description = "Path at which to store server state.";
    };

    base-url = mkOption {
      type = str;
      description = "Base URL at which the Grafana server is reachable.";
    };

    admin-password-file = mkOption {
      type = str;
      description = "Path to a file containing the admin user password.";
    };

    port = mkOption {
      type = port;
      description = "Port on which to listen for HTTP requests (on localhost)";
      default = 5402;
    };

    datasources = mkOption {
      type = attrsOf (submodule datasourceOpts);
      description = "A map of datasources supplied to Grafana.";
      default = { };
    };

    oauth = let
      oauthOpts.options = {
        hostname = mkOption {
          type = str;
          description = "Host of the OAuth server.";
        };

        client-id = mkOption {
          type = str;
          description = "Path to file containing the Grafana OAuth client ID.";
        };

        client-secret = mkOption {
          type = str;
          description =
            "Path to file containing the Grafana OAuth client secret.";
        };

        slug = mkOption {
          type = str;
          description = "The application slug on the OAuth server.";
        };
      };
    in mkOption {
      type = nullOr (submodule oauthOpts);
      default = null;
    };
  };

  config = mkIf cfg.enable {
    services.grafana = {
      enable = true;
      dataDir = "${cfg.state-directory}/data";
      settings = {
        server = {
          root_url = cfg.base-url;
          http_addr = "127.0.0.1";
          http_port = cfg.port;
          protocol = "http";
        };

        security = {
          admin_password = "$__file{${cfg.admin-password-file}}";
          secret_key = "$__file{${cfg.secret-key-file}}";
        };

        database = {
          type = "sqlite3";
          path = "${cfg.state-directory}/database.sqlite";
        };

        provision = {
          enable = true;
          datasources.settings.datasources = let
            mkDatasource = ds: {
              editable = false;
              isDefault = ds.default;
              inherit (ds) name type url;
            };
          in map mkDatasource (attrValues cfg.datasources);
        };

        auth = mkIf (!isNull cfg.oauth) {
          signout_redirect_url =
            "https://${cfg.oauth.hostname}/application/o/${cfg.oauth.slug}/end-session/";
          oauth_auto_login = true;
        };

        "auth.generic_oauth" = mkIf (!isNull cfg.oauth) {
          name = "Authentik";
          enabled = true;
          client_id = "$__file{${cfg.oauth.client-id}}";
          client_secret = "$__file{${cfg.oauth.client-secret}}";
          scopes = "openid email profile";
          auth_url = "https://${cfg.oauth.hostname}/application/o/authorize/";
          token_url = "https://${cfg.oauth.hostname}/application/o/token/";
          api_url = "https://${cfg.oauth.hostname}/application/o/userinfo/";
          role_attribute_path = concatStringsSep " || " [
            "contains(groups[*], 'Metrics Admins') && 'Admin'"
            "contains(groups[*], 'Metrics Editors') && 'Editor'"
            "'Viewer'"
          ];
        };
      };
    };
  };
}
