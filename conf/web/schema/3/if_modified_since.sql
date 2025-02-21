drop function if exists web.if_modified_since
;
create or replace function web.if_modified_since
    ( p_header jsonb
    )
returns timestamptz
language sql
immutable
as $function$
    select to_timestamp
        ( (
            -- "value" is an array of strings; we extract the first element.
            SELECT "value"->>0
            -- "jsonb_each" returns a set of key-value pairs. This method allows
            -- us to select the key case-insensitively.
            FROM jsonb_each(p_header)
            WHERE lower("key") = 'if-modified-since'
          )
        , 'Dy, DD Mon YYYY HH24:MI:SS TZ'
        )
$function$
;

comment on function web.if_modified_since is
$$Converts the value of the If-Modified-Since header, e.g.
'Wed, 19 Feb 2025 16:40:16 GMT', to a timestamp.
$$;
