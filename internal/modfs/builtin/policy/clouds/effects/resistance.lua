-- Cloud immunity queries the live actor and the same monster definition used
-- by elemental damage. Specialized kinds add their own non-elemental rules.
local component = require("constants.component")
local damage = require("policy.magic.damage")

local resistance = {}

-- Cloud immunity must read the same live monster resistance as damage,
-- including current gear and timed effects, before rolling exposure.
function resistance.monster(ctx, actor, resistance_id)
    if not ctx:get(actor, component.ACTOR) then
        return 0
    end

    return damage.monster_resistance(ctx, actor, resistance_id)
end

-- Use the shared spell resistance calculation for player cloud damage.
function resistance.player(ctx, actor, resistance_id)
    local damage = require("policy.magic.damage")

    return damage.player_resistance(ctx, actor, resistance_id)
end

return resistance
