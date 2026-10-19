local petrification = require("policy.combat.player_petrification")

local system = {}

-- Theory of operation: Petrification progress is committed before regeneration observes the player form.
-- Petrification progresses after status durations, before the next regeneration step.
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
