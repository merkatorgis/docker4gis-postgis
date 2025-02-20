drop function if exists web.if_modified_since(text)
;
create or replace function web.if_modified_since
    ( p_value text
    )
returns timestamptz
language sql
immutable
as $function$
    select to_timestamp
        ( p_value
        , 'Dy, DD Mon YYYY HH24:MI:SS TZ'
        )
$function$
;

comment on function web.if_modified_since(text) is $$
Converts a string in the format of the If-Modified-Since header, e.g.
'Wed, 19 Feb 2025 16:40:16 GMT', to a timestamp.
$$;


drop function if exists web.if_modified_since(jsonb)
;
create or replace function web.if_modified_since
    ( p_header jsonb
    )
returns timestamptz
language sql
immutable
as $function$
    -- Use the overloaded text-parameter function.
    select web.if_modified_since ((
        -- "value" is an array of strings; we extract the first element.
        SELECT "value"->>0
        -- "jsonb_each" returns a set of key-value pairs. This method allows us
        -- to select the key case-insensitively.
        FROM jsonb_each(p_header)
        WHERE lower("key") = 'if-modified-since'
    ))
$function$
;

comment on function web.if_modified_since(jsonb) is $$
Converts the value of the If-Modified-Since header, e.g.
'Wed, 19 Feb 2025 16:40:16 GMT', to a timestamp.
$$;
