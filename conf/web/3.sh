#!/bin/bash

pushd schema/"$(basename "$0" .sh)" &&
    pg.sh --set ON_ERROR_STOP=on -1 \
        -f if_modified_since.sql \
        -f last_modified.sql \
        -f cache_path_result.sql &&
    popd || exit
