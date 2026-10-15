local golubria = require("policy.magic.effects.translocation.golubria")

local system = {}

function system.update(ctx, actor)
    golubria.trigger(ctx, actor)
end

register.system({
    id = "magic.golubria_passage.trigger",
    scope = "active",
    query = {},
    after = { "world.movement" },
    before = { "attack.combat" },
    update = system.update,
})

return system
