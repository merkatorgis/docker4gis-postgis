#!/bin/bash
set -e

[ -z "$POSTFIX_DOMAIN" ] ||
	echo "POSTFIX_DOMAIN=$POSTFIX_DOMAIN" >>"$ENV_FILE"

SHM_SIZE=${SHM_SIZE:-64m}

POSTGIS_PORT=$(docker4gis/port.sh "${POSTGIS_PORT:-5432}")

CERTIFICATES=$DOCKER_BINDS_DIR/certificates/$DOCKER_USER
mkdir -p "$CERTIFICATES"

mkdir -p "$FILEPORT"
mkdir -p "$RUNNER"

docker container run --restart "$RESTART" --name "$DOCKER_CONTAINER" \
	--env-file "$ENV_FILE" \
	--env POSTGRES_LOG_STATEMENT="$POSTGRES_LOG_STATEMENT" \
	--shm-size="$SHM_SIZE" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount type=bind,source="$RUNNER",target=/runner \
	--mount type=bind,source="$CERTIFICATES",target=/certificates \
	--mount source="$DOCKER_VOLUME",target=/var/lib/postgresql/data \
	--network "$DOCKER_NETWORK" \
	--publish "$POSTGIS_PORT":5432 \
	--detach "$DOCKER_IMAGE" postgis "$@"

# Provision the PGDATABASE variable.
eval "$(docker container exec "$DOCKER_CONTAINER" env | grep PGDATABASE)"
# Wait until all DDL has run.
sql="alter database $PGDATABASE set app.ddl_done to false"
docker container exec "$DOCKER_CONTAINER" pg.sh -c "$sql" >/dev/null
while
	sql="select current_setting('app.ddl_done', true)"
	value=$(docker container exec "$DOCKER_CONTAINER" pg.sh -Atc "$sql")
	[ "$value" != "true" ]
do
	sleep 1
done
