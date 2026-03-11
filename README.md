# ERPNext 15 + Payments + LMS on Dokploy

This repository is intended for deploying **ERPNext 15 + Payments + LMS** on **Dokploy** using a custom Docker image.

It is designed for setups where:

- you want **ERPNext 15** for better stability,
- you need **Payments** installed before **LMS**,
- and you may be using **HAProxy externally** instead of Dokploy's Traefik routing.

---

## Included files

Your repository should contain:

- `docker-compose.yml`
- `Dockerfile`
- `apps.json`
- `template.toml` *(optional, for Dokploy template-style generation)*

---

## App order

The install order used here is:

1. `erpnext`
2. `payments`
3. `lms`

This matters because LMS may require Payments to already exist in the environment.

---

## apps.json

```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/payments",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/lms",
    "branch": "main"
  }
]
```

---

## Dockerfile

```dockerfile
FROM frappe/erpnext:version-15

USER root
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe/frappe-bench

RUN bench get-app --branch version-15 payments https://github.com/frappe/payments && \
    bench get-app --branch main lms https://github.com/frappe/lms
```

---

## docker-compose.yml notes

Important points in the compose file:

- custom image is built locally with `build: .`
- image name is `erpnext15-payments-lms:latest`
- site creation installs apps in this order:

```yaml
INSTALL_APP_ARGS: ${INSTALL_APP_ARGS:---install-app erpnext --install-app payments --install-app lms}
```

- if using **HAProxy externally**, keep:

```yaml
ports:
  - "${HTTP_PORT:-8098}:8080"
```

- if using **Dokploy Domains + Traefik**, remove `ports:` and use `expose: 8080` instead.

---

## Dokploy deployment options

### Option A: Deploy as Docker Compose from a public GitHub repository

This is the simplest and most reliable option.

1. Push the repository to GitHub.
2. In Dokploy, create a new **Docker Compose** application.
3. Select **GitHub repository**.
4. Point Dokploy to your public repository.
5. Add the required environment variables.
6. Deploy.

### Option B: Use as a Dokploy template

If you want Dokploy to auto-generate values such as:

- domain
- admin password
- database root password

then add a `template.toml` file and import it using Dokploy's template workflow.

---

## Recommended environment variables for first deploy

If deploying as a normal Docker Compose app, set these values in Dokploy:

```env
SITE_NAME=erp.example.com
FRAPPE_SITE_NAME_HEADER=erp.example.com
ADMIN_PASSWORD=ChangeThisAdminPassword
DB_ROOT_PASSWORD=ChangeThisDatabasePassword

CONFIGURE=1
CREATE_SITE=1
ENABLE_DB=1
MIGRATE=0
REGENERATE_APPS_TXT=1

IMAGE_NAME=erpnext15-payments-lms:latest
PULL_POLICY=build

DB_HOST=db
DB_PORT=3306
MARIADB_VERSION=10.11
REDIS_VERSION=7-alpine
SOCKETIO_PORT=9000
HTTP_PORT=8098

UPSTREAM_REAL_IP_ADDRESS=127.0.0.1
UPSTREAM_REAL_IP_HEADER=X-Forwarded-For
UPSTREAM_REAL_IP_RECURSIVE=off
```

---

## Recommended values after the first successful deploy

Once the site has been created successfully, change these values:

```env
CONFIGURE=0
CREATE_SITE=0
REGENERATE_APPS_TXT=0
MIGRATE=0
```

This prevents Dokploy from trying to recreate the site on every redeploy.

---

## When to use MIGRATE=1

Only enable migrations when:

- updating ERPNext code,
- updating custom apps,
- or changing app versions.

Typical workflow:

1. Set `MIGRATE=1`
2. Deploy
3. Set `MIGRATE=0`
4. Deploy again later as normal

---

## HAProxy setup guidance

If HAProxy is in front of Dokploy, keep `ports:` enabled in `frontend` and forward traffic to the published host port.

Recommended HAProxy headers:

- `Host`
- `X-Forwarded-For`
- `X-Forwarded-Proto`
- `X-Forwarded-Host`

Example backend target:

- Dokploy host: `192.168.1.50`
- ERPNext published port: `8098`

HAProxy backend example target:

```haproxy
server erpnext 192.168.1.50:8098 check
```

---

## Dokploy template example

If you want auto-generated values from the repository, add a `template.toml` like this:

```toml
[variables]
site_name = "${domain}"
admin_password = "${password:32}"
db_root_password = "${password:32}"
http_port = "8098"

[config]
env = [
  "SITE_NAME=${site_name}",
  "FRAPPE_SITE_NAME_HEADER=${site_name}",
  "ADMIN_PASSWORD=${admin_password}",
  "DB_ROOT_PASSWORD=${db_root_password}",
  "CONFIGURE=1",
  "CREATE_SITE=1",
  "ENABLE_DB=1",
  "MIGRATE=0",
  "REGENERATE_APPS_TXT=1",
  "PULL_POLICY=build",
  "IMAGE_NAME=erpnext15-payments-lms:latest",
  "MARIADB_VERSION=10.11",
  "REDIS_VERSION=7-alpine",
  "DB_HOST=db",
  "DB_PORT=3306",
  "SOCKETIO_PORT=9000",
  "HTTP_PORT=${http_port}",
  "UPSTREAM_REAL_IP_ADDRESS=127.0.0.1",
  "UPSTREAM_REAL_IP_HEADER=X-Forwarded-For",
  "UPSTREAM_REAL_IP_RECURSIVE=off"
]
```

---

## Suggested GitHub repository name

A clear repository name would be:

```text
erpnext15-payments-lms
```

---

## Final recommendation

For your current setup, the safest approach is:

- use **ERPNext 15**,
- install **Payments before LMS**,
- deploy from a **public GitHub repository**,
- use **Docker Compose in Dokploy** first,
- and only move to a Dokploy template if you want auto-generated variables directly from the repo.

