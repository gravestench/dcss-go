-- The fifth entry changes guards at absolute depth 15. Keep the choice in
-- this one map hook so ordinary Trove entrances do not acquire guards.
local directives = require("constants.vault_directives")

local entry = {}

-- Deeper guards bring friends on the source map's l cells and tint their
-- marble approach. The source's two branches intentionally draw no RNG.
local function guardians(api)
    if api:absolute_depth() <= 15 then
        api:emit(directives.KMONS, "e = vault guard")
        return
    end

    api:emit(directives.KMONS, "el = vault guard")
    api:emit(directives.COLOUR, "l = blue")
    api:emit(directives.FTILE, "l = floor_marble")
end

entry.guardians = guardians

return entry
