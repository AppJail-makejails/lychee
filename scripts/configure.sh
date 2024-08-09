#!/bin/sh

set -e

. /scripts/lib.subr

WWWDIR=/usr/local/www/Lychee

for DIR in /conf /uploads /sym /logs; do
    if [ ! -d "${DIR}" ]; then
        info "Creating '${DIR}'"

        mkdir -p "${DIR}"
        chown www:www "${DIR}"
    fi
done

if [ ! -L "${WWWDIR}/public/uploads" ]; then
    info "Creating symlink to /uploads"

    cp -a "${WWWDIR}/public/uploads"/* /uploads
    rm -rf "${WWWDIR}/public/uploads"
    ln -s /uploads "${WWWDIR}/public/uploads"
fi

if [ ! -L "${WWWDIR}/public/sym" ]; then
    info "Creating symlink to /sym"

    touch "${WWWDIR}/public/sym/empty_file"
    cp -a "${WWWDIR}/public/sym"/* /sym
    rm -rf "${WWWDIR}/public/sym"
    ln -s /sym "${WWWDIR}/public/sym"
fi

if [ ! -L "${WWWDIR}/storage/sym" ]; then
    info "Creating symlink to /logs"

    touch "${WWWDIR}/storage/logs/empty_file"
    cp -a "${WWWDIR}/storage/logs"/* /logs
    rm -rf "${WWWDIR}/storage/logs"
    ln -s /logs "${WWWDIR}/storage/logs"
fi

if [ ! -f /conf/.env ]; then
    info "Copying environment configuration file"

    cp -va "${WWWDIR}/.env" /conf/.env
fi

if [ ! -L "${WWWDIR}/.env" ]; then
    info "Creating symlink to /conf/.env"

    rm -f "${WWWDIR}/.env"
    ln -s /conf/.env "${WWWDIR}/.env"
fi

if [ "${LYCHEE_DB_CONNECTION}" = "sqlite" ] || [ -z "${LYCHEE_DB_CONNECTION}" ]; then
    if [ -n "${LYCHEE_DB_DATABASE}" ]; then
        if [ ! -f "${LYCHEE_DB_DATABASE}" ]; then
            warn "Specified SQLite database (${LYCHEE_DB_DATABASE}) doesn't exist. Creating it ..."
            warn "Make sure your database is on a persistent volume"

            touch "${LYCHEE_DB_DATABASE}"
        fi

        chown www:www "${LYCHEE_DB_DATABASE}"
    else
        export LYCHEE_DB_DATABASE="${WWWDIR}/database/database.sqlite"

        if [ ! -f /conf/database.sqlite ]; then
            info "Copying SQLite database"

            cp -va "${LYCHEE_DB_DATABASE}" /conf/database.sqlite
        fi

        if [ ! -L "${LYCHEE_DB_DATABASE}" ]; then
            info "Creating symlink to /conf/database.sqlite"

            rm -f "${LYCHEE_DB_DATABASE}"
            ln -s /conf/database.sqlite "${LYCHEE_DB_DATABASE}"
        fi
    fi
fi

env | grep -Ee '^LYCHEE_[A-Z_]+=.+$' | while IFS= read -r env; do
    case "${env}" in
        LYCHEE_SKIP_PERMISSIONS_CHECK) continue ;;
    esac

	name=`printf "%s" "${env}" | cut -d= -f1`
	name=`printf "%s" "${name}" | sed -Ee 's/^LYCHEE_(.+)/\1/'`
	value=`printf "%s" "${env}" | cut -d= -f2-`

	info "Configuring ${name} -> ${value}"

	option "${name}" "${value}"
done

if [ ! -f /conf/user.css ]; then
    touch /conf/user.css
fi

if [ ! -L "${WWWDIR}/public/dist/user.css" ]; then
    rm -f "${WWWDIR}/public/dist/user.css"
    ln -s /conf/user.css "${WWWDIR}/public/dist/user.css"
fi

if [ ! -f /conf/custom.js ]; then
    touch /conf/custom.js
fi

if [ ! -L "${WWWDIR}/public/dist/custom.js" ]; then
    rm -f "${WWWDIR}/public/dist/custom.js"
    ln -s /conf/custom.js "${WWWDIR}/public/dist/custom.js"
fi

if [ ! -f /logs/laravel.log ]; then
    info "Creating laravel's log"

    touch /logs/laravel.log
fi

if [ -n "${LYCHEE_SKIP_PERMISSIONS_CHECK}" ]; then
    warn "Skipping permissions check"
else
    info "Fixing permissions"

    find /sym /uploads /logs -type d \( ! -user "www" -o ! -group "www" \) -exec chown -R "www":"www" \{\} \;
	find /conf/.env /sym /uploads /logs \( ! -user "www" -o ! -group "www" \) -exec chown "www":"www" \{\} \;
	find /conf/user.css /conf/custom.js /logs/laravel.log \( ! -user "www" -o ! -group "www" \) -exec chown www:"www" \{\} \;
	find /sym /uploads /logs -type d \( ! -perm -ug+w -o ! -perm -ugo+rX -o ! -perm -g+s \) -exec chmod -R ug+w,ugo+rX,g+s \{\} \;
	find /conf/user.css /conf/custom.js /conf/.env /sym /uploads /logs \( ! -perm -ug+w -o ! -perm -ugo+rX \) -exec chmod ug+w,ugo+rX \{\} \;
fi

if [ ! -f /conf/.done ]; then
    info "Generating the key to make sure that cookies cannot be decrypted"
    (cd "${WWWDIR}"; su -m www -c 'php artisan key:generate -n')

    info "Migrating the database"
    (cd "${WWWDIR}"; su -m www -c 'php artisan migrate --force')

    if [ -n "${LYCHEE_ADMIN_USER}" -a -n "${LYCHEE_ADMIN_PASSWORD}" ]; then
        info "Creating admin account"
        (cd "${WWWDIR}"; su -m www -c 'php artisan lychee:create_user "${LYCHEE_ADMIN_USER}" "${LYCHEE_ADMIN_PASSWORD}"')
    fi

    touch /conf/.done
fi
