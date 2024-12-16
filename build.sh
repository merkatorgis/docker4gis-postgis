#!/bin/bash

POSTGRESQL_VERSION=${1:-$POSTGRESQL_VERSION}
POSTGRESQL_VERSION=${POSTGRESQL_VERSION:-17}

POSTGIS_VERSION=${2:-$POSTGIS_VERSION}
POSTGIS_VERSION=${POSTGIS_VERSION:-3.5}

PYTHON=${PYTHON:-python3}
MYSQL_VERSION=${MYSQL_VERSION:-0.8.33-1}
ODBC_FDW_VERSION=${ODBC_FDW_VERSION:-0.5.2.3}
MONGO_FDW_VERSION=${MONGO_FDW_VERSION:-5_5_2}
PGJWT_VERSION=${PGJWT_VERSION:-f3d82fd}
PGXN_VERSION=${PGXN_VERSION:-1.3.2}
PGSAFEUPDATE_VERSION=${PGSAFEUPDATE_VERSION:-1.5}

docker image build \
	--build-arg POSTGRESQL_VERSION="$POSTGRESQL_VERSION" \
	--build-arg POSTGIS_VERSION="$POSTGIS_VERSION" \
	--build-arg PYTHON="$PYTHON" \
	--build-arg MYSQL_VERSION="$MYSQL_VERSION" \
	--build-arg ODBC_FDW_VERSION="$ODBC_FDW_VERSION" \
	--build-arg MONGO_FDW_VERSION="$MONGO_FDW_VERSION" \
	--build-arg PGJWT_VERSION="$PGJWT_VERSION" \
	--build-arg PGXN_VERSION="$PGXN_VERSION" \
	--build-arg PGSAFEUPDATE_VERSION="$PGSAFEUPDATE_VERSION" \
	--build-arg PGHOST="$PGHOST" \
	--build-arg PGHOSTADDR="$PGHOSTADDR" \
	--build-arg PGPORT="$PGPORT" \
	--build-arg PGDATABASE="$PGDATABASE" \
	--build-arg PGUSER="$PGUSER" \
	--build-arg PGPASSWORD="$PGPASSWORD" \
	-t "$IMAGE" .
