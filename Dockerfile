ARG POSTGRESQL_VERSION
ARG POSTGIS_VERSION

# postgis/postgis:10-2.5 <- debian:stretch = 9
# postgis/postgis:10-3.2 <- debian:bullseye = 11
# postgis/postgis:11-2.5 <- debian:stretch = 9
# postgis/postgis:11-3.3 <- debian:bullseye = 11
# postgis/postgis:12-3.3 <- debian:bullseye = 11
# postgis/postgis:13-3.3 <- debian:bullseye = 11
# postgis/postgis:14-3.3 <- debian:bullseye = 11
# postgis/postgis:15-3.3 <- debian:bullseye = 11
FROM postgis/postgis:${POSTGRESQL_VERSION}-${POSTGIS_VERSION}

# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG POSTGRESQL_VERSION
ENV POSTGRESQL_VERSION=${POSTGRESQL_VERSION}

# Allow configuration before things start up.
COPY conf/entrypoint /
ENTRYPOINT ["/entrypoint"]
CMD ["postgis"]

# This may come in handy.
ONBUILD ARG DOCKER_USER
ONBUILD ENV DOCKER_USER=$DOCKER_USER


ENV DEBIAN_FRONTEND=noninteractive

# update the list of installable packages
RUN apt update

ARG PYTHON
ENV PYTHON=${PYTHON}

# install packages we want throughout
RUN apt install -y \
    apt-transport-https \
    ${PYTHON} \
    ${PYTHON}-psycopg2

# install packaged postgresql extensions
RUN apt install -y \
    postgresql-${POSTGRESQL_VERSION}-ogr-fdw \
    postgresql-${POSTGRESQL_VERSION}-plsh \
    postgresql-${POSTGRESQL_VERSION}-pldebugger

ARG MYSQL_VERSION
# install mysql repository to
# install package mysql-connector-odbc
ENV MYSQL_VERSION=${MYSQL_VERSION}
# https://dev.mysql.com/get/mysql-apt-config_0.8.16-1_all.deb
COPY conf/src/mysql-apt-config_${MYSQL_VERSION}_all.deb /
# hard downloaded archived debian9 version (postgis 10-2.5), since apt support
# for debian9 is dropped
COPY conf/src/mysql-connector-odbc-debian-9 /mysql-connector-odbc
RUN . /etc/os-release; \
    if [ "$VERSION_ID" = 9 ]; then \
    cp /mysql-connector-odbc/bin/* /usr/bin; \
    cp /mysql-connector-odbc/lib/* /usr/lib/x86_64-linux-gnu/odbc; \
    else \
    apt install -y lsb-release wget; \
    dpkg -i /mysql-apt-config_${MYSQL_VERSION}_all.deb; \
    apt update; \
    apt install -y mysql-connector-odbc; \
    fi
# install proper paths to the odbc drivers
RUN template=$(mktemp); \
    add() { echo "$1" >> "$template"; }; \
    add '[MySQL ODBC 8.0 Unicode Driver]'; \
    add "Driver=$(ls /usr/lib/x86_64-linux-gnu/odbc/libmyodbc*w.so)"; \
    add '[MySQL ODBC 8.0 ANSI Driver]'; \
    add "Driver=$(ls /usr/lib/x86_64-linux-gnu/odbc/libmyodbc*a.so)"; \
    odbcinst -i -d -f "$template"

# install packages needed for building several components
ENV BUILD_TOOLS="build-essential"
ENV BUILD_TOOLS="${BUILD_TOOLS} postgresql-server-dev-${POSTGRESQL_VERSION}"
RUN apt install -y ${BUILD_TOOLS}

ARG ODBC_FDW_VERSION
# compile & install odbc_fdw
ENV ODBC_FDW_VERSION=${ODBC_FDW_VERSION}
ENV BUILD_TOOLS="${BUILD_TOOLS} unixodbc-dev"
RUN apt install -y ${BUILD_TOOLS}
# https://github.com/CartoDB/odbc_fdw/archive/0.5.1.tar.gz
ADD conf/src/odbc_fdw-${ODBC_FDW_VERSION}.tar.gz /
RUN cd /odbc_fdw-${ODBC_FDW_VERSION}; \
    make; \
    make install

ARG MONGO_FDW_VERSION
# compile & install mongo_fdw
ENV MONGO_FDW_VERSION=${MONGO_FDW_VERSION}
ENV BUILD_TOOLS="${BUILD_TOOLS} cmake"
ENV BUILD_TOOLS="${BUILD_TOOLS} pkg-config"
ENV BUILD_TOOLS="${BUILD_TOOLS} libssl-dev"
ENV BUILD_TOOLS="${BUILD_TOOLS} libsnappy-dev"
ENV BUILD_TOOLS="${BUILD_TOOLS} zlib1g-dev"
ENV BUILD_TOOLS="${BUILD_TOOLS} libzstd-dev"
RUN apt install -y ${BUILD_TOOLS} \
    wget \
    openssl \
    libsnappy1v5 \
    zlib1g \
    zstd
# https://github.com/EnterpriseDB/mongo_fdw/archive/REL-5_2_8.tar.gz
ADD conf/src/mongo_fdw-REL-${MONGO_FDW_VERSION}.tar.gz /
RUN cd /mongo_fdw-REL-${MONGO_FDW_VERSION}; \
    ./autogen.sh --with-master; \
    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH":/lib/pkgconfig/; \
    make; \
    make install

ARG PGJWT_VERSION
# compile & install pgjwt
ENV PGJWT_VERSION=${PGJWT_VERSION}
# https://github.com/michelp/pgjwt/tarball/master
ADD conf/src/michelp-pgjwt-${PGJWT_VERSION}.tar.gz /
RUN cd /michelp-pgjwt-${PGJWT_VERSION}; \
    make install

# install the Microsoft ODBC driver for SQL Server
# https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15
ENV BUILD_TOOLS="${BUILD_TOOLS} curl"
ENV BUILD_TOOLS="${BUILD_TOOLS} apt-transport-https"
ENV BUILD_TOOLS="${BUILD_TOOLS} ca-certificates"
RUN apt install -y ${BUILD_TOOLS}
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
#Download appropriate package for the OS version
# https://www.ionos.com/digitalguide/server/know-how/how-to-check-debian-version/
# https://unix.stackexchange.com/a/316087
RUN curl https://packages.microsoft.com/config/debian/$(cut -d. -f1 /etc/debian_version)/prod.list \
    > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update; \
    ACCEPT_EULA=Y apt-get install -y msodbcsql17
# optional: for bcp and sqlcmd
RUN ACCEPT_EULA=Y apt-get install -y mssql-tools; \
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile; \
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc; \
    . ~/.bashrc
# optional: for unixODBC development headers
RUN apt-get install -y unixodbc-dev
# optional: kerberos library for debian-slim distributions
RUN apt-get install -y libgssapi-krb5-2
# prevent TCP Provider: Error code 0x2746
# https://stackoverflow.com/a/59503719
# https://github.com/microsoft/msphpsql/issues/1021
RUN sed -i 's/CipherString = DEFAULT@SECLEVEL=2/CipherString = DEFAULT@SECLEVEL=1/g' /etc/ssl/openssl.cnf

ARG PGXN_VERSION
# compile & install PostgreSQL Extension Network client
ENV PGXN_VERSION=${PGXN_VERSION}
# install package python-pip, and python-setuptools,
# which is also needed when running the pgxn client
RUN apt install -y ${PYTHON}-setuptools ${PYTHON}-pip
RUN pip3 install pytest-runner || true
# https://github.com/pgxn/pgxnclient/archive/v${PGXN_VERSION}.tar.gz
ADD conf/src/pgxnclient-${PGXN_VERSION}.tar.gz /
RUN cd /pgxnclient-${PGXN_VERSION}; \
    ${PYTHON} setup.py install

# install extension safeupdate from pgxn
# https://github.com/eradman/pg-safeupdate
# http://postgrest.org/en/v7.0.0/admin.html?highlight=safeupdate#block-full-table-operations
RUN pgxn install safeupdate
# # compile & install install extension safeupdate (when pgxn doesn't work)
# ARG PGSAFEUPDATE_VERSION
# ENV PGSAFEUPDATE_VERSION=${PGSAFEUPDATE_VERSION}
# # https://github.com/eradman/pg-safeupdate/archive/refs/tags/${PGSAFEUPDATE_VERSION}.tar.gz
# ADD conf/src/pg-safeupdate-${PGSAFEUPDATE_VERSION}.tar.gz /
# RUN cd /pg-safeupdate-${PGSAFEUPDATE_VERSION} && \
# 	make && \
# 	make install

# for postgresql < 14, install range_agg as an extension from pgxn
# https://pgxn.org/dist/range_agg/
RUN [ "$POSTGRESQL_VERSION" -lt 14 ] && pgxn install range_agg || true

# remove packages used for building several components
RUN apt remove -y ${BUILD_TOOLS}; \
    apt autoremove -y


# install plugin runner
COPY conf/.plugins/runner/runner.sh /usr/local/bin

# install plugin pg
COPY conf/.plugins/pg/pg.sh /usr/local/bin
COPY conf/.plugins/pg/refresh.sh /usr/local/bin

# install plugin mail
COPY conf/.plugins/mail /tmp/.plugins/mail
RUN /tmp/.plugins/mail/install.sh

# install plugin bats
COPY conf/.plugins/bats /tmp/.plugins/bats
RUN /tmp/.plugins/bats/install.sh

# install tool schema.sh
COPY conf/schema.sh /usr/local/bin

# install source for schema mail
COPY conf/mail /tmp/mail

# install source for schema web
COPY conf/web /tmp/web

# install database server administrative scripts
COPY ["conf/entrypoint", "conf/conf.sh", "conf/onstart.sh", "conf/subconf.sh", "/"]

# install tools
COPY conf/last.sh /usr/local/bin/
COPY conf/dump_restore /usr/local/bin/dump
COPY conf/dump_restore /usr/local/bin/restore
COPY conf/dump_restore /usr/local/bin/upgrade
COPY conf/dump_restore /usr/local/bin/dump_schema
COPY conf/dump_restore /usr/local/bin/restore_schema

# copy custom postgres configuration files
COPY conf/postgres /etc/postgresql
ENV CONFIG_FILE=/etc/postgresql/postgresql.conf
RUN mv "${CONFIG_FILE}" "${CONFIG_FILE}.template"
RUN [ "$POSTGRESQL_VERSION" -le 11 ] \
    && echo 'hostssl all             all             all                     md5       clientcert=1' >> /etc/postgresql/pg_hba.conf \
    || echo 'hostssl all             all             all                     cert' >> /etc/postgresql/pg_hba.conf

# include a "client" image's conf scripts where onstart.sh will find them
ONBUILD COPY conf /tmp/conf


# Extension template, as required by `dg component`.
COPY template /template/
# Make this an extensible base component; see
# https://github.com/merkatorgis/docker4gis/tree/npm-package/docs#extending-base-components.
COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args
ONBUILD RUN cp /tmp/conf/args /.docker4gis
