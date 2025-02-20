drop function if exists web.last_modified
;
create or replace function web.last_modified
    ( p_value timestamptz
    )
returns jsonb
language plpgsql
immutable
as $function$
declare
    v_last_modified text := to_char
        ( p_value AT TIME ZONE 'GMT'
        , 'Dy, DD Mon YYYY HH24:MI:SS'
        ) || ' GMT';
begin
    if v_last_modified is null then
        return null::jsonb;
    else
        return jsonb_build_object
            ( 'Last-Modified', array[v_last_modified]
            );
    end if;
end $function$
;

comment on function web.last_modified is
$$
Converts a timestamp to a string in the format of the Last-Modified header, e.g.
'Wed, 19 Feb 2025 16:40:16 GMT'.
$$;
