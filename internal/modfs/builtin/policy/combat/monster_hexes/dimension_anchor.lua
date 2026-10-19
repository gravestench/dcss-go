local component = require("constants.component")
local status = require("policy.combat.monster_hexes.status")
local streams = require("constants.rng_streams")

local anchor = {}

-- Example: anchor.apply(ctx, nil, defender) with player with pending teleport -> teleport removed and anchor stored
-- DCSS cancels a pending teleport when the anchor lands. Future teleport
-- attempts consult the same saved state through translocation policy.
function anchor.apply(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        local turns = 12 + ctx:random(streams.MONSTER_SPELL, 15)

        status.anchor(ctx, defender, turns * 10)

        if ctx:has(defender, component.PLAYER_TELEPORT) then
            ctx:remove(defender, component.PLAYER_TELEPORT)
        end

        ctx:emit("combat", "You are anchored in space.")

        return
    end

    local turns = 20 + ctx:random(streams.MONSTER_SPELL, 11)

    status.anchor(ctx, defender, turns * 10)
end

return anchor
