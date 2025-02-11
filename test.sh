#!/usr/bin/env sh
# Check that the date reported
# shellcheck disable=SC2290,SC3039,SC2154
set -o errexit -o nounset -o noclobber # -o xtrace
dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd); cd "$dir"

if ! ${in_docker:-false}; then
    # wait until healthy to detach so our curl command won't fail
    docker compose up --build --wait  # --detach
    docker compose exec -e in_docker=true nginx '/test.sh' 1>&2 2>/dev/null \
        || trap 'echo FAILED. Error 27 >&2; exit 27' EXIT
    docker compose down
    exit
fi

#set -x
let() { echo "+ $1$2$3"; eval "$1$2$3"; }

test_all() {
    server_date=$(curl http://localhost -sI | sed -En 's/^Date: (.*)$/\1/p')
    # We take the date header returned by nginx so that we can parse it into
    # an epoch timestamp.
    let server_date  = "\"$server_date\""
    let server_epoch = "$(date --date "$server_date" +%s)"
    let local_epoch  = "$(date +%s)"
    let real_epoch   = "$(FAKETIME='' date -u +%s)"

    let server_vs_local = "$((local_epoch - server_epoch))"
    # no more than 10 seconds between nginx and /bin/date
    [ "$server_vs_local" -le 10 ]

    let server_vs_real = "$((real_epoch - server_epoch))"
    # at least a full day of seconds between real and fake time
    [ "$server_vs_real" -ge 86400 ]
}
test_all
# repeated tests in case we think an nginx worker might stop reporting
# the expected time
for _ in $(seq 30); do
    : # sleep 1; test_all
done
