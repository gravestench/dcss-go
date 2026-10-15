local dragons = require("policy.magic.effects.summons.dragon_call")

local system = {}

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
