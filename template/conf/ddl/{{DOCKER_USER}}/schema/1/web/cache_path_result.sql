drop function if exists cache_path_result
;
create or replace function cache_path_result
    ( p_header jsonb
    , p_last_modified timestamptz
    , p_max_age integer default 0
    )
returns jsonb
language sql
immutable
security definer
as $function$
    -- Run with security definer to allow access to the web schema.
    select * from web.cache_path_result
        ( p_header
        , p_last_modified
        , p_max_age
        );
$function$
;

grant execute on function cache_path_result
to web_user
, web_anon
;

comment on function cache_path_result is
$$Construct a result object for the cache_path function, based on the
If-Modified-Since header and the last_modified timestamp.
$$;
