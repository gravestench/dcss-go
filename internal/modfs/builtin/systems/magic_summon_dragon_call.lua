local dragons = require("policy.magic.effects.summons.dragon_call")

local system = {}

-- Theory of operation: A successful cast can create a dragon before movement changes spawn occupancy.
-- Dragon's Call can add its summon after casting, before the movement phase.
function system.update(ctx, entity)
    if entity == ctx:player() then
        dragons.advance(ctx, entity)
    end
end

register.system({
    id = "magic.summon.dragon_call",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = system.update,
})

return system
