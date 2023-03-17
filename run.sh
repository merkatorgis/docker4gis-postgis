#!/bin/bash
set -e

POSTGRES_USER=${1:-postgres}
POSTGRES_PASSWORD=${2:-postgres}
POSTGRES_DB=${3:-$DOCKER_USER}

SHM_SIZE=${SHM_SIZE:-64m}
POSTGRES_LOG_STATEMENT=$POSTGRES_LOG_STATEMENT

IMAGE=$IMAGE
CONTAINER=$CONTAINER
DOCKER_ENV=$DOCKER_ENV
RESTART=$RESTART
NETWORK=$NETWORK
FILEPORT=$FILEPORT
VOLUME=$VOLUME

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-v "$(docker4gis/bind.sh "$FILEPORT" /fileport)" \
	--mount source="$VOLUME",target=/var/lib/postgresql/data \
	--network "$NETWORK" \
	--shm-size="$SHM_SIZE" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e SECRET="$SECRET" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e POSTGRES_LOG_STATEMENT="$POSTGRES_LOG_STATEMENT" \
	-e "$(docker4gis/noop.sh POSTFIX_DOMAIN "$POSTFIX_DOMAIN")" \
	-e POSTGRES_USER="$POSTGRES_USER" \
	-e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
	-e POSTGRES_DB="$POSTGRES_DB" \
	-e CONTAINER="$CONTAINER" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/secrets /secrets)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/certificates /certificates)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/runner /util/runner/log)" \
	-p "$POSTGIS_PORT":5432 \
	-d "$IMAGE" postgis "$@"
