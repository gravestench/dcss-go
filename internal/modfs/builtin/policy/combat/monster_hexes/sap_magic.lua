local component = require("constants.component")
local status = require("policy.combat.monster_hexes.status")
local streams = require("constants.rng_streams")

local sap = {
    -- Source Sap Magic deliberately bypasses willpower saving throws.
    saving_throw = false,
}

function sap.apply(ctx, _, defender)
    local turns = 20 + ctx:random(streams.MONSTER_SPELL, 11)

    status.sap_magic(ctx, defender, turns * 10)

    if ctx:has(defender, component.PLAYER) then
        ctx:emit("combat", "Your magic begins to sap your strength.")
    end
end

return sap
