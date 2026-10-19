-- Theory of operation: World movement damages an actor as it moves; this
-- ordered action pass then ages its saved barbs duration before death checks.
local barbs = require("policy.combat.barbs")
local component = require("constants.component")

local system = {}

-- Tick only wounded actors, using the scheduler's actual elapsed aut.
function system.update(ctx, actor, elapsed_aut)
    barbs.tick(ctx, actor, elapsed_aut)
end

register.system({
    id = "combat.barbs.tick",
    scope = "active",
    query = { component.BARBS },
    after = { "attack.combat" },
    before = { "actor.death" },
    update = system.update,
})

return system
