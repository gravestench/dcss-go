local brilliance = require("policy.combat.monster_support.brilliance")
local component = require("constants.component")

local system = {}

-- Theory of operation: the active monster first spends its own aura and
-- empowerment time; a remaining caster aura then refreshes eligible allies.
-- Both timers live on actors, so saves and level travel keep their lifetimes.
function system.update(ctx, monster, elapsed_aut)
    brilliance.tick(ctx, monster, elapsed_aut)
end

register.system({
    id = "combat.monster_brilliance.tick",
    scope = "active",
    query = { component.ACTOR },
    before = { "monster.decision" },
    update = system.update,
})

return system
