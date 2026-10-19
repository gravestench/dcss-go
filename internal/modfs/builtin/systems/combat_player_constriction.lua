local constriction = require("policy.combat.player_constriction")

local system = {}

-- Theory of operation: A player action damages held victims before death cleanup collects kills.
-- Player-held victims take constriction damage after attacks, before death cleanup.
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
