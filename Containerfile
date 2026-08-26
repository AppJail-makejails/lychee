ARG FREEBSD_RELEASE
ARG PHPVER

FROM ghcr.io/appjail-makejails/php:${FREEBSD_RELEASE}-${PHPVER}

ARG NO_PKGCLEAN

LABEL org.opencontainers.image.title="Lychee" \
    org.opencontainers.image.description="Great looking and easy-to-use photo-management-system" \
    org.opencontainers.image.source="https://github.com/AppJail-makejails/lychee" \
    org.opencontainers.image.url="https://github.com/AppJail-makejails/lychee" \
    org.opencontainers.image.vendor="DtxdF" \
    org.opencontainers.image.authors="Jesús Daniel Colmenares Oviedo <dtxdf@disroot.org>"

ARG PHPVER

RUN set -xe; \
    \
    umask 0022; \
    \
    pkg update; \
    pkg install lycheeorg bash nginx; \
    \
    if [ -z "${NO_PKGCLEAN}" ]; then \
        pkg clean -a; \
        rm -rf /var/cache/pkg/*; \
    fi; \
    rm -rf /var/db/pkg/repos/*; \
    \
    php_version=`php -r 'echo PHP_VERSION;' | sed -Ee 's/^([0-9]+)\.([0-9]+)\.[0-9]+$/\1\2/'`; \
    \
    if [ "${php_version}" != "${PHPVER}" ]; then \
        echo "Installed PHP version is different from what expected ( ${php_version} != ${PHPVER} )"; \
        exit 1; \
    fi

RUN set -xe; \
    \
    umask 0022; \
    \
    mv /usr/local/www/lycheeorg /app

RUN set -xe; \
    \
    umask 0022; \
    \
    echo "upload_max_filesize=128M" > /usr/local/etc/php/custom.ini; \
    echo "post_max_size=128M" >> /usr/local/etc/php/custom.ini; \
    echo "memory_limit=\${PHP_MEMORY_LIMIT:-1024M}" >> /usr/local/etc/php/custom.ini; \
    echo "max_execution_time=\${PHP_MAX_EXECUTION_TIME:-3000}" >> /usr/local/etc/php/custom.ini; \
    echo "expose_php=Off" >> /usr/local/etc/php/custom.ini; \
    echo "display_errors=Off" >> /usr/local/etc/php/custom.ini; \
    echo "log_errors=On" >> /usr/local/etc/php/custom.ini

WORKDIR /app

# Copy entrypoint and validation scripts
COPY files/scripts/00-conf-check.sh /usr/local/bin/00-conf-check.sh
COPY files/scripts/01-validate-env.sh /usr/local/bin/01-validate-env.sh
COPY files/scripts/02-dump-env.sh /usr/local/bin/02-dump-env.sh
COPY files/scripts/03-db-check.sh /usr/local/bin/03-db-check.sh
COPY files/scripts/04-user-setup.sh /usr/local/bin/04-user-setup.sh
COPY files/scripts/05-permissions-check.sh /usr/local/bin/05-permissions-check.sh
COPY files/scripts/create-admin-user.sh /usr/local/bin/create-admin-user.sh
COPY files/scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -xe; \
    \
    chmod 555 /usr/local/bin/00-conf-check.sh \
    /usr/local/bin/01-validate-env.sh \
    /usr/local/bin/02-dump-env.sh \
    /usr/local/bin/03-db-check.sh \
    /usr/local/bin/04-user-setup.sh \
    /usr/local/bin/05-permissions-check.sh \
    /usr/local/bin/create-admin-user.sh \
    /usr/local/bin/entrypoint.sh; \
    \
    sed -i '' -E \
        -e 's/^user = www/user = noroot/' \
        -e 's/^group = www/group = noroot/' \
        /usr/local/etc/php-fpm.d/www.conf; \
    \
    mkdir -p /data /config; \
    chmod -R 775 /data /config

# When opcache is enabled, it sigfault if DB_CONNECTION is set to
# something like mysql or pgsql. This is a workaround.
RUN rm -f /usr/local/etc/php/ext-10-opcache.ini

# Expose port 8000 (NGINX)
EXPOSE 80

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

COPY files/nginx.conf /usr/local/etc/nginx/nginx.conf

CMD ["nginx", "-c", "/usr/local/etc/nginx/nginx.conf", "-g", "daemon off;"]
