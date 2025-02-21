#!/bin/bash

schema() {
    pg.sh --set ON_ERROR_STOP=on -1 \
        -c "set search_path to $SCHEMA, public" \
        "$@"
}

(
    cd "$(dirname "$0")" &&
        schema -f auth_path.sql &&
        schema -f cache_path.sql &&
        # This one can't be done like the others, since we need to call
        # $SCHEMA.cache_path_result.
        pg.sh -c "
            DROP FUNCTION IF EXISTS $SCHEMA.cache_path
            ;
            CREATE OR REPLACE FUNCTION $SCHEMA.cache_path
                ( \"Path\" text
                , \"Query\" jsonb
                , \"Header\" jsonb
                )
            RETURNS jsonb
            LANGUAGE plpgsql
            STABLE
            AS \$function\$
            declare
                v_last_modified timestamptz;
            begin
            --     raise log \$log\$
            -- Path=%
            -- Query=%
            -- Header=%\$log\$, \"Path\", \"Query\", \"Header\";

                -- Replace now() with a value that is selected based on the Path and/or
                -- Query parameters.
                select now() into v_last_modified
                ;

                return $SCHEMA.cache_path_result
                    ( \"Header\"
                    , v_last_modified
                    , p_max_age := 0
                    );
            end \$function\$
            ;

            grant execute on function $SCHEMA.cache_path
            to web_user
            , web_anon
            ;

            comment on function $SCHEMA.cache_path is
            \$\$This function is the endpoint for the default value of the CACHE_PATH variable
            (http://$DOCKER_USER-api:8080/rpc/cache_path) in the Proxy component, whith
            PostgREST as the API component.
            \$\$;
        " &&
        schema -f new_user.sql &&
        schema -f change_password.sql &&
        schema -f login.sql &&
        # This one can't be done like the others, since we need to call
        # $SCHEMA.login.
        pg.sh -c "
            create or replace function $SCHEMA.save_password
                ( email citext
                , password text
                )
            returns web.jwt_token
            language sql
            security definer
            as \$function\$
                -- web.save_password throws user not found exception
                select web.save_password(email, password)
                ;
                select $SCHEMA.login(email, password)
                ;
            \$function\$
        " &&
        schema -f save_password.sql &&
        schema -f logout.sql
)
