#!/usr/bin/env bash
# Obtain Let's Encrypt certificates for naacademy.tech (and optional SANs).
#
# Usage (on the server, after DNS A/AAAA records point here):
#   export LETSENCRYPT_EMAIL='you@yourdomain.com'
#   sudo bash deploy/ssl/obtain-cert.sh
#
# Env:
#   LETSENCRYPT_EMAIL      — required (Let's Encrypt account / expiry notices)
#   LETSENCRYPT_DOMAIN     — primary name (default: naacademy.tech)
#   LETSENCRYPT_EXTRA_DOMAINS — comma-separated extra names (default: www.naacademy.tech)
#   CERTBOT_MODE           — webroot | standalone | nginx-plugin (default: webroot)
#
# webroot (recommended): nginx serves /.well-known/acme-challenge/ from /var/www/html — keeps port 80 in use.
# standalone: needs TCP 80 free; stops compose `admin` if present — conflicts if nginx listens on :80.
# nginx-plugin: needs python3-certbot-nginx and an enabled nginx site for your domains.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EMAIL="${LETSENCRYPT_EMAIL:?Set LETSENCRYPT_EMAIL (e.g. export LETSENCRYPT_EMAIL=admin@naacademy.tech)}"
PRIMARY="${LETSENCRYPT_DOMAIN:-naacademy.tech}"
EXTRAS_RAW="${LETSENCRYPT_EXTRA_DOMAINS:-www.naacademy.tech}"
MODE="${CERTBOT_MODE:-webroot}"

if [[ "${EUID:-0}" -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

DOMAIN_ARGS=( -d "$PRIMARY" )
while IFS= read -r -d ',' part || [[ -n "$part" ]]; do
  x="$(echo "$part" | xargs)"
  [[ -n "$x" ]] && DOMAIN_ARGS+=( -d "$x" )
done <<< "${EXTRAS_RAW},"

compose_stop_admin() {
  if command -v docker >/dev/null 2>&1 && [[ -f "$REPO_ROOT/docker-compose.yml" ]]; then
    (cd "$REPO_ROOT" && docker compose stop admin) || true
  fi
}

compose_start_admin() {
  if command -v docker >/dev/null 2>&1 && [[ -f "$REPO_ROOT/docker-compose.yml" ]]; then
    (cd "$REPO_ROOT" && docker compose start admin) || true
  fi
}

run_standalone() {
  compose_stop_admin
  # shellcheck disable=SC2064
  trap 'compose_start_admin' EXIT
  certbot certonly --standalone "${DOMAIN_ARGS[@]}" \
    --non-interactive --agree-tos --email "$EMAIL" \
    --preferred-challenges http
}

run_webroot() {
  certbot certonly --webroot -w /var/www/html "${DOMAIN_ARGS[@]}" \
    --non-interactive --agree-tos --email "$EMAIL"
}

run_nginx_plugin() {
  certbot --nginx "${DOMAIN_ARGS[@]}" \
    --non-interactive --agree-tos --email "$EMAIL"
}

case "$MODE" in
  standalone) run_standalone ;;
  webroot)    run_webroot ;;
  nginx-plugin) run_nginx_plugin ;;
  *)
    echo "CERTBOT_MODE must be standalone, webroot, or nginx-plugin" >&2
    exit 1
    ;;
esac

echo
echo "Certificates are typically under: /etc/letsencrypt/live/${PRIMARY}/"
echo "Reload nginx: sudo nginx -t && sudo systemctl reload nginx"
