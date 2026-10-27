-- Pilot host helper (flua → typical Gforth). Regen:
--   flua fsoc/flua/path_join.lua > fsoc/flua/path_join.4th
--
-- @forth fjson.str-concat ( a1 u1 a2 u2 -- a3 u3 )
-- @forth fjson.str-free ( a u -- )

-- Join a1/u1 and a2/u2 with "/". Allocated; caller fjson.str-free on result.
function fsoc_join(a1, u1, a2, u2)
  local sa, su = "/"
  local mid_a, mid_u = fjson_str_concat(a1, u1, sa, su)
  local out_a, out_u = fjson_str_concat(mid_a, mid_u, a2, u2)
  fjson_str_free(mid_a, mid_u)
  return out_a, out_u
end
