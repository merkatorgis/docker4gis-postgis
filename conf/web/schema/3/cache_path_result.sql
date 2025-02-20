drop function if exists web.cache_path_result
;
create or replace function web.cache_path_result
    ( p_header jsonb
    , p_last_modified timestamptz
    , p_max_age integer default 0
    )
returns jsonb
language plpgsql
immutable
as $function$
declare
    v_if_modified_since timestamptz := web.if_modified_since("p_header");
    v_stale boolean := true;
    v_header jsonb;
    v_max_age text := 'no-cache';
begin
    if v_if_modified_since is not null then
        v_stale := p_last_modified > v_if_modified_since;
    end if;

    if p_max_age > 0 then
        v_max_age := 'max-age=' || p_max_age;
    end if;

    v_header := web.last_modified("p_last_modified") || jsonb_build_object
        ( 'Cache-Control', array[format('private, %s, immutable', v_max_age)]
        );

    return jsonb_build_object
        ( 'Header', v_header
        , 'Stale', v_stale
        );
end $function$
;

comment on function web.cache_path_result is
$$Construct a result object for the cache_path function, based on the
If-Modified-Since header and the last_modified timestamp.
$$;
