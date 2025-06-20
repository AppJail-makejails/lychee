# Lychee

Lychee is a free photo-management tool, which runs on your server or web-space. Installing is a matter of seconds. Upload, manage and share photos like from a native application. Lychee comes with everything you need and all your photos are stored securely.

 lycheeorg.github.io/
 
 <img src="https://raw.githubusercontent.com/LycheeOrg/Lychee/master/Banner.png" >

## How to use this Makejail

### Standalone

```sh
appjail makejail \
    -j lychee \
    -f gh+AppJail-makejails/lychee \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose=80 \
    -V LYCHEE_APP_URL=http://lychee \
    -V LYCHEE_TIMEZONE=America/Caracas \
        -- \
        --lychee_nginx_server_name lychee
```

### Deploy using appjail-director

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
      - expose: 80
    arguments:
      - lychee_nginx_server_name: lychee
    environment:
      - LYCHEE_APP_URL: http://lychee
      - LYCHEE_TIMEZONE: America/Caracas
      - LYCHEE_ADMIN_USER: !ENV '${ADMIN_USER}'
      - LYCHEE_ADMIN_PASSWORD: !ENV '${ADMIN_PASS}'
    volumes:
      - lc-conf: lychee-conf
      - lc-uploads: lychee-uploads
      - lc-sym: lychee-sym
      - lc-logs: lychee-logs

default_volume_type: '<volumefs>'

volumes:
  lc-conf:
    device: .volumes/lc-conf
  lc-uploads:
    device: .volumes/lc-uploads
  lc-sym:
    device: .volumes/lc-sym
  lc-logs:
    device: .volumes/lc-logs
```

**.env**:

```
DIRECTOR_PROJECT=lychee
ADMIN_USER=lychee
ADMIN_PASS=1ych33123@
```

### Arguments

* `lychee_tag` (default: `13.5`): See [#tags](#tags).
* `lychee_ajspec` (default: `gh+AppJail-makejails/lychee`): Entry point where the `appjail-ajspec(5)` file is located.
* `lychee_nginx_conf` (default: `files/nginx.conf`): NGINX configuration file.
* `lychee_nginx_server_name` (default: `localhost`): [server_name](https://nginx.org/en/docs/http/ngx_http_core_module.html#server_name)'s value.

### Volumes

| Name           | Owner | Group | Perm | Type | Mountpoint  |
| -------------- | ----- | ----- | ---- | ---- | ----------- |
| lychee-conf    | 80    | 80    |  -   |  -   | /conf       |
| lychee-uploads | 80    | 80    |  -   |  -   | /uploads    |
| lychee-sym     | 80    | 80    |  -   |  -   | /sym        |
| lychee-logs    | 80    | 80    |  -   |  -   | /logs       |

## Tags

| Tag    | Arch    | Version        | Type   | `lychee_version` | `lychee_php_version` |
| ------ | ------- | -------------- | ------ | ---------------- | -------------------- |
| `13.5` | `amd64` | `13.5-RELEASE` | `thin` | `6.6.5`          | `83`                 |
| `14.3` | `amd64` | `14.3-RELEASE` | `thin` | `6.6.5`          | `83`                 |

## Notes

1. The ideas present in the Docker image of Lychee are taken into account for users who are familiar with it.
