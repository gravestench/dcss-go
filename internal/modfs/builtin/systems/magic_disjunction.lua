local disjunction = require("policy.magic.effects.translocation.disjunction")

local system = {}

function system.update(ctx, actor, aut)
    if actor == ctx:player() then
        disjunction.pulse(ctx, actor, aut)
    end
end

register.system({
    id = "magic.disjunction.pulse",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "magic.player_status.tick" },
    update = system.update,
})

return system
