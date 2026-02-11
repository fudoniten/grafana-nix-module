# Grafana NixOS Module

A clean, minimal NixOS module for running Grafana with custom datasource provisioning and OAuth2 support.

## Overview

This module wraps the built-in [`services.grafana`](https://search.nixos.org/options?channel=nixos-unstable&show=services.grafana.enable) NixOS service with:

- **Datasource provisioning**: Automatically configure Prometheus, Loki, and other datasources
- **OAuth2 integration**: Built-in support for Authentik-based auth with role-based access control
- **Secrets management**: Secure password and API key handling via `$__file{}` interpolation
- **SQLite storage**: Lightweight, zero-configuration database backend
- **Minimal configuration**: Simple options that cover common use cases

## Features

✅ Automatic datasource provisioning
✅ OAuth2 / Authentik integration
✅ Secrets via files (not embedded in config)
✅ Role-based access control (Admin, Editor, Viewer)
✅ Customizable port and base URL
✅ SQLite database (no external DB needed)

## Quick Start

### Basic Configuration (No OAuth)

```nix
{
  fudo.services.grafana = {
    enable = true;
    state-directory = "/var/lib/grafana";
    base-url = "http://localhost:5402";
    admin-password-file = "/run/secrets/grafana-admin-pwd";
    secret-key-file = "/run/secrets/grafana-secret-key";
    
    datasources = {
      prometheus = {
        name = "Prometheus";
        type = "prometheus";
        url = "http://prometheus:9090";
        default = true;
      };
    };
  };
}
```

### With OAuth2 / Authentik

```nix
{
  fudo.services.grafana = {
    enable = true;
    state-directory = "/var/lib/grafana";
    base-url = "https://grafana.example.com";
    admin-password-file = "/run/secrets/grafana-admin-pwd";
    secret-key-file = "/run/secrets/grafana-secret-key";
    
    datasources = {
      prometheus = {
        name = "Prometheus";
        type = "prometheus";
        url = "http://prometheus:9090";
      };
      loki = {
        name = "Loki";
        type = "loki";
        url = "http://loki:3100";
      };
    };
    
    oauth = {
      hostname = "auth.example.com";
      client-id = "/run/secrets/grafana-oauth-client-id";
      client-secret = "/run/secrets/grafana-oauth-client-secret";
      slug = "grafana";
    };
  };
}
```

## Module Options

### Required Options

| Option | Type | Description |
|--------|------|-------------|
| `state-directory` | string | Path to store Grafana state (database, config, etc.) |
| `base-url` | string | Base URL where Grafana is reachable (e.g., `http://localhost:5402`) |
| `admin-password-file` | string | Path to file containing admin password |
| `secret-key-file` | string | Path to file containing secret encryption key |

### Optional Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `port` | int | 5402 | HTTP listen port (localhost only) |
| `datasources` | attrSet | {} | Map of datasources to provision |
| `oauth` | attrSet or null | null | OAuth2 configuration (optional) |

## Secrets Management

Secrets are handled via file references (not embedded in config). Grafana reads files at startup.

```bash
openssl rand -base64 32 | tee /run/secrets/grafana-admin-pwd
openssl rand -hex 32 | tee /run/secrets/grafana-secret-key
```

## Architecture

- **Service**: Built on NixOS's `services.grafana`
- **Database**: SQLite (file-based, no setup needed)
- **Network**: HTTP only, listens on 127.0.0.1 (use reverse proxy for HTTPS)
- **Auth**: Local admin user + optional OAuth2
- **Provisioning**: Datasources configured automatically on startup

## Integration Examples

### With Home Assistant

```nix
fudo.services.grafana.datasources.homeassistant = {
  name = "Home Assistant";
  type = "prometheus";
  url = "http://homeassistant.local:9090";
};
```

### With Frigate NVR

```nix
fudo.services.grafana.datasources.frigate = {
  name = "Frigate";
  type = "prometheus";
  url = "http://frigate:5000/metrics";
};
```

## Troubleshooting

- **Datasources not provisioning**: Check datasource URLs are reachable, review Grafana logs
- **OAuth not working**: Verify credentials files exist, check hostname and base-url match OAuth provider
- **Admin login failing**: Verify password file exists and is readable

## References

- [NixOS Grafana service docs](https://search.nixos.org/options?channel=nixos-unstable&show=services.grafana)
- [Grafana Official Docs](https://grafana.com/docs/)
- [Authentik OAuth2 Docs](https://goauthentik.io/)
