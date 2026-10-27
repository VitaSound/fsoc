-- Pilot: fjson via @forth (cell stack, no RTTI). Regen:
--   flua fsoc/flua/json_has.lua > fsoc/flua/json_has.4th
--
-- @forth fjson.contains? ( hay hlen suba slen -- f )

function fsoc_json_has(ha, hu, sa, su)
  return fjson_contains_(ha, hu, sa, su)
end
