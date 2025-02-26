grant usage on schema wms
to public
;

drop function if exists wms.envelope(integer, text)
;
create or replace function wms.envelope
  ( p_srid integer
  , p_envelope text default current_setting('wms.envelope')
  )
returns geometry
language plpgsql
stable
as $function$
declare
  v_parts text[] := string_to_array
    ( p_envelope
    , ','
    );
begin
  return ST_Transform
    ( ST_MakeEnvelope
      ( v_parts[1]::float
      , v_parts[2]::float
      , v_parts[3]::float
      , v_parts[4]::float
      , v_parts[5]::integer
      )
    , p_srid
    );
end $function$;

grant execute on function wms.envelope(integer, text)
to public
;

comment on function wms.envelope(integer, text) is
$$Create a box geometry in the given SRID from the 'wms.envelope' setting, or an
ad hoc envelope string.
$$;