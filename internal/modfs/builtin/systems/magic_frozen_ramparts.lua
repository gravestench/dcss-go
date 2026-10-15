local ramparts = require("policy.magic.effects.translocation.frozen_ramparts")

local system = {}

function system.update(ctx, actor, aut)
    ramparts.tick(ctx, actor, aut)
end

register.system({
    id = "magic.frozen_ramparts.tick",
    scope = "active",
    query = {},
    after = { "world.movement", "attack.combat" },
    before = { "actor.death" },
    update = system.update,
})

return system
