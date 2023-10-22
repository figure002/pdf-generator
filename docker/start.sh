#!/bin/sh

set -e

SCRIPT_PATH="$(dirname "$(readlink -f $0)")"

docker compose build --pull
docker compose run --rm java bash
