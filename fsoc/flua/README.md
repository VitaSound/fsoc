# fsoc/flua — host helpers from Lua subset

Pilot: write a small host helper in flua’s Lua subset, emit **typical Gforth**,
include next to hand-written Forth. Not a Lua VM — stack cells (`a u`) stay
visible; call existing words via `-- @forth`.

## Regen

```bash
export FLUA_HOME="$HOME/flua"   # or FECO_WORKSPACE/flua
export PATH="$FLUA_HOME/bin:$PATH"

flua fsoc/flua/path_join.lua > fsoc/flua/path_join.4th
flua fsoc/flua/json_has.lua  > fsoc/flua/json_has.4th
```

Commit both `.lua` and generated `.4th`.

## Files

| Source | Forth word | Role |
|--------|------------|------|
| `path_join.lua` | `fsoc_join` | join two path pieces with `/` via `fjson.str-concat` |
| `json_has.lua` | `fsoc_json_has` | thin wrapper over `fjson.contains?` |

## Load

After `fjson` is available (normal fsoc host load):

```forth
require ./fsoc/flua/path_join.4th
require ./fsoc/flua/json_has.4th
```
