\ Pilot: fjson via @forth (cell stack, no RTTI). Regen:
\   flua fsoc/flua/json_has.lua > fsoc/flua/json_has.4th
\ @forth fjson.contains? ( hay hlen suba slen -- f )
\ ( ha hu sa su -- r )
: fsoc_json_has { ha hu sa su }
  ha hu sa su fjson.contains? 
;
