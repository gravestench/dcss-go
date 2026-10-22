-- The layered path replaces only this map's hook. A typed witness record
-- proves the effective handler ran at the original DES directive position.
local effects = require("constants.vault_effects")

local hunt = {}

-- A marker leaves an inspectable generation result without changing the
-- base files or teaching the Go loader a special case for this test mod.
local function loot_mix(api)
    api:record(effects.MARKER, {
        glyph = "~",
        identity = "ossuary_mod_hook_witness",
    })
end

hunt.loot_mix = loot_mix

return hunt
