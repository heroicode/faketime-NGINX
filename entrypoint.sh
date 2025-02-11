#!/usr/bin/env sh
# Ensure nginx.conf contains `env` directives for faketime so that the
# nginx workers report the same time as every other process.
set -o errexit -o nounset +o noclobber

# echo args "$@" >/dev/stderr

[ -f /etc/nginx/nginx.conf ] || { echo ERROR: missing nginx.conf; exit 9; }

[ -e /etc/nginx/nginx.conf.template ] || \
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.template
{
    cat /etc/nginx/nginx.conf.template
    printf "\n\n%s\n\n" "$(env \
        | grep FAKETIME \
        | grep -v FAKETIME_SHARED \
        | xargs -Iz echo 'env "z";')"
} > /etc/nginx/nginx.conf

# We are done setting everything up, so now we run the original entrypoint
# from the nginx base image.
exec /docker-entrypoint.sh "$@"
