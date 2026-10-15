local constriction = require("policy.combat.player_constriction")

local system = {}

function system.update(ctx, actor, aut)
    if actor == ctx:player() then
        constriction.player_action(ctx, aut)
    end
end

register.system({
    id = "combat.player_constriction.tick",
    scope = "active",
    query = {},
    after = { "attack.combat" },
    before = { "actor.death" },
    update = system.update,
})

return system
