# Lychee

Lychee is a free photo-management tool, which runs on your server or web-space. Installing is a matter of seconds. Upload, manage and share photos like from a native application. Lychee comes with everything you need and all your photos are stored securely.

lycheeorg.dev

<img src="https://raw.githubusercontent.com/LycheeOrg/Lychee/master/Banner.png" width="30%" height="auto" alt="Lychee logo">

## How to use this Makejail

### Standalone

```console
$ APP_KEY=$(openssl rand -base64 32)
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -e APP_KEY="base64:${APP_KEY}" \
    -e DB_CONNECTION="sqlite" \
    -e APP_URL="http://lychee" \
    -e APP_TIMEZONE="America/Caracas" \
    ghcr.io/appjail-makejails/lychee lychee
```

!!! warning

    Since you are using the OCI image, changes to environment variables require a container restart, as the server loads and caches the configuration at startup.

See [Configuration](https://lycheeorg.dev/docs/getting-started/configuration/) for all available environment variables.

### Deploy using `appjail-director`

**appjail-director.yml**:

```yaml
options:
  - virtualnet: ':<random> default'
  - nat:

services:
  lychee:
    name: lychee
    makejail: gh+AppJail-makejails/lychee
    options:
      - secret: lychee
      - depend: lychee-db
    oci:
      environment:
        - DB_CONNECTION: pgsql
        - DB_HOST: lychee-db
        - DB_PORT: 5432
        - DB_DATABASE: lychee
        - DB_USERNAME: lychee
        - DB_PASSWORD_FILE: /secrets/lychee/db_password
        - APP_KEY_FILE: /secrets/lychee/app_key
        - APP_URL: !ENV '${APP_URL:http://lychee}'
        - APP_TIMEZONE: !ENV '${APP_TIMEZONE:UTC}'
    volumes:
      - uploads: /app/public/uploads
      - app-storage: /app/storage/app
      - logs: /app/storage/logs
      - tmp: /app/storage/tmp
      - user-css: app/public/dist/user.css
      - custom-js: app/public/dist/custom.js

  lychee-db:
    name: lychee-db
    priority: 98
    makejail: gh+AppJail-makejails/postgres
    options:
      - secret: lychee
      - container: 'args:--pull'
      - template: !ENV '${PWD}/template.conf'
    oci:
      environment:
        - POSTGRES_DB: lychee
        - POSTGRES_USER: lychee
        - POSTGRES_PASSWORD_FILE: /secrets/lychee/db_password
    volumes:
      - db: /var/db/postgres

volumes:
  db:
    device: !ENV '${PWD}/lychee/db'
  uploads:
    device: !ENV '${PWD}/lychee/uploads'
  app-storage:
    device: !ENV '${PWD}/lychee/app-storage'
  logs:
    device: !ENV '${PWD}/lychee/logs'
  tmp:
    device: !ENV '${PWD}/lychee/tmp'
  user-css:
    device: !ENV '${PWD}/conf/user.css'
  custom-js:
    device: !ENV '${PWD}/conf/custom.js'
```

**template.conf**:

```
exec.start: "/bin/sh /etc/rc"
exec.stop: "/bin/sh /etc/rc.shutdown jail"
sysvshm: new
sysvsem: new
sysvmsg: new
mount.devfs
persist
```

**.env**:

```dotenv
DIRECTOR_PROJECT=lychee
```

**Console**:

```console
$ mkdir -p conf
$ touch conf/custom.js conf/user.css
$ appjail secrets create -s lychee/app_key "base64:$(openssl rand -base64 32)"
$ appjail secrets create -s lychee/db_password $(openssl rand -base64 32)
$ appjail-director up
Starting Director (project:lychee) ...
Creating lychee-db (lychee-db) ... Done.
 - Configuring environment (OCI):
   - POSTGRES_DB ... Done.
   - POSTGRES_USER ... Done.
   - POSTGRES_PASSWORD_FILE ... Done.
Starting lychee-db (lychee-db) ... Done.
Creating lychee (lychee) ... Done.
 - Configuring environment (OCI):
   - DB_CONNECTION ... Done.
   - DB_HOST ... Done.
   - DB_PORT ... Done.
   - DB_DATABASE ... Done.
   - DB_USERNAME ... Done.
   - DB_PASSWORD_FILE ... Done.
   - APP_KEY_FILE ... Done.
   - APP_URL ... Done.
   - APP_TIMEZONE ... Done.
Starting lychee (lychee) ... Done.
Finished: lychee
```

### Worker Mode for Horizontal Scaling (Recommended)

The basic single-service setup handles both web requests and background jobs. However, the requests are limited to 30s by default, which may not be sufficient for large uploads or processing. For better performance, run dedicated worker services:

```yaml
options:
  - virtualnet: ':<random> default'
  - nat:

services:
  lychee:
    name: lychee
    priority: 98
    makejail: gh+AppJail-makejails/lychee
    options:
      - secret: lychee
      - depend: lychee-db
    oci:
      environment:
        - DB_CONNECTION: pgsql
        - DB_HOST: lychee-db
        - DB_PORT: 5432
        - DB_DATABASE: lychee
        - DB_USERNAME: lychee
        - DB_PASSWORD_FILE: /secrets/lychee/db_password
        - APP_KEY_FILE: /secrets/lychee/app_key
        - APP_URL: !ENV '${APP_URL:http://lychee}'
        - APP_TIMEZONE: !ENV '${APP_TIMEZONE:UTC}'
        - QUEUE_CONNECTION: database
    volumes:
      - uploads: /app/public/uploads
      - app-storage: /app/storage/app
      - logs: /app/storage/logs
      - tmp: /app/storage/tmp

  lychee-worker:
    name: lychee-worker
    makejail: gh+AppJail-makejails/lychee
    options:
      - secret: lychee
      - depend: lychee
      - depend: lychee-db
    oci:
      environment:
        - LYCHEE_MODE: worker
        - DB_CONNECTION: pgsql
        - DB_HOST: lychee-db
        - DB_PORT: 5432
        - DB_DATABASE: lychee
        - DB_USERNAME: lychee
        - DB_PASSWORD_FILE: /secrets/lychee/db_password
        - APP_KEY_FILE: /secrets/lychee/app_key
        - APP_URL: !ENV '${APP_URL:http://lychee}'
        - APP_TIMEZONE: !ENV '${APP_TIMEZONE:UTC}'
        - QUEUE_CONNECTION: database
    volumes:
      - uploads: /app/public/uploads
      - app-storage: /app/storage/app
      - logs: /app/storage/logs
      - tmp: /app/storage/tmp

  lychee-db:
    name: lychee-db
    priority: 97
    makejail: gh+AppJail-makejails/postgres
    options:
      - secret: lychee
      - container: 'args:--pull'
      - template: !ENV '${PWD}/template.conf'
    oci:
      environment:
        - POSTGRES_DB: lychee
        - POSTGRES_USER: lychee
        - POSTGRES_PASSWORD_FILE: /secrets/lychee/db_password
    volumes:
      - db: /var/db/postgres

volumes:
  db:
    device: !ENV '${PWD}/lychee/db'
  uploads:
    device: !ENV '${PWD}/lychee/uploads'
  app-storage:
    device: !ENV '${PWD}/lychee/app-storage'
  logs:
    device: !ENV '${PWD}/lychee/logs'
  tmp:
    device: !ENV '${PWD}/lychee/tmp'
```

**Critical Requirements for Worker Mode**:

1. Set `QUEUE_CONNECTION: database` (or `redis`) in **both** API and worker services
2. Set `LYCHEE_MODE: worker` in worker service only
3. Ensure both services share the same database and volume mounts

### Arguments (stage: build)

* `lychee_from` (default: `ghcr.io/appjail-makejails/lychee`): Location of OCI image. See also [OCI Configuration](#oci-configuration).
* `lychee_tag` (default: `latest`): OCI image tag. See also [OCI Configuration](#oci-configuration).

### Environment (OCI image)

* `PGID` (default: `1000`): Equivalent to `PUID` but for the Process Group ID.
* `PUID` (default: `1000`): Process User ID for the container's main process, allowing you to match the owner of files written to mounted host volumes to your host system's user. Writable volumes are changed based on this environment variable.
* `UMASK` (default: `0022`): Override default umask setting.

## OCI Configuration

```yaml
build:
  variants:
    - tag: 15.1
      containerfile: Containerfile
      aliases: ["latest"]
      default: true
      args:
        FREEBSD_RELEASE: "15.1"
        PHPVER: "84"
        NO_PKGCLEAN: "1"
      cache_dirs:
        - "pkgcache0:/var/cache/pkg"
        - /home/user/Tests/Ports/files/usr/local/etc/pkg/repos:/usr/local/etc/pkg/repos
        - /usr/local/poudriere/data/packages/150amd64-local:/repo
```
