#!/bin/bash
set -e

POSTGRES_USER=${1:-postgres}
POSTGRES_PASSWORD=${2:-postgres}
POSTGRES_DB=${3:-$POSTGRES_USER}

SHM_SIZE=${SHM_SIZE:-64m}
POSTGRES_LOG_STATEMENT=$POSTGRES_LOG_STATEMENT

POSTGIS_PORT=$(docker4gis/port.sh "${POSTGIS_PORT:-5432}")

IMAGE=$IMAGE
CONTAINER=$CONTAINER
DOCKER_ENV=$DOCKER_ENV
RESTART=$RESTART
NETWORK=$NETWORK
IP=$IP
FILEPORT=$FILEPORT
VOLUME=$VOLUME

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount source="$VOLUME",target=/var/lib/postgresql/data \
	--network "$NETWORK" \
	--ip "$IP" \
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
	--mount type=bind,source="$DOCKER_BINDS_DIR"/secrets,target=/secrets \
	--mount type=bind,source="$DOCKER_BINDS_DIR"/certificates,target=/certificates \
	--mount type=bind,source="$DOCKER_BINDS_DIR"/runner,target=/util/runner/log \
	-p "$POSTGIS_PORT":5432 \
	-d "$IMAGE" postgis "$@"

# wait until all DDL has run
sql="alter database $POSTGRES_DB set app.ddl_done to false"
docker container exec "$CONTAINER" pg.sh -c "$sql" >/dev/null 2>&1
while
	sql="select current_setting('app.ddl_done', true)"
	result=$(docker container exec "$CONTAINER" pg.sh -Atc "$sql")
	[ "$result" != "true" ]
do
	sleep 1
done
