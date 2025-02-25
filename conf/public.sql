-- See https://docs.geoserver.org/main/en/user/data/database/sqlsession.html.

-- select set_config
--     ( 'wms.envelope'
--     , '${envelope, -180,-90,180,90,4326}'
--     , false
--     );
drop function if exists public.wms_envelope
;
create or replace function public.wms_envelope
  ( p_srid integer
  )
returns geometry
language plpgsql
stable
as $function$
declare
  v_parts text[] := string_to_array
    ( current_setting('wms.envelope')
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

grant execute on function public.wms_envelope
to public
;
