drop function if exists wms.env
;
create or replace function wms.env
  ( p_key text
  , p_value text
  )
returns void
language plpgsql
immutable
as $function$
begin
  perform set_config
      ( 'wms.' || lower(p_key)
      , p_value
      , false
      );
end $function$;

grant execute on function wms.env
to public
;

-- See https://docs.geoserver.org/main/en/user/data/database/sqlsession.html.

drop function if exists wms.envelope(text)
;
create or replace function wms.envelope
  ( p_envelope text
  )
returns void
language plpgsql
immutable
as $function$
begin
  if p_envelope is null or p_envelope = '' then
    p_envelope := '-180,-90,180,90,4326';
  end if;
  perform wms.env
    ( 'envelope'
    , p_envelope
    );
end $function$;

grant execute on function wms.envelope(text)
to public
;
