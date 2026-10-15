local petrification = require("policy.combat.player_petrification")

local system = {}

function system.tick(ctx, actor, elapsed)
    if actor == ctx:player() then
        petrification.tick(ctx, actor, elapsed)
    end
end

register.system({
    id = "magic.player_petrification.tick",
    scope = "active",
    query = {},
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.tick,
})

return system
