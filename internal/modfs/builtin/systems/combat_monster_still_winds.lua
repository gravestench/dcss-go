local component = require("constants.component")
local wind = require("policy.combat.monster_support.still_winds")

local system = {}

-- Theory of operation: the active caster ages its saved aura time before
-- choosing an intent. Cloud placement derives the level restriction from
-- that status, so no separate level flag can outlive the caster.
function system.update(ctx, caster, elapsed_aut)
    wind.tick(ctx, caster, elapsed_aut)
end

register.system({
    id = "combat.monster_still_winds.tick",
    scope = "active",
    query = { component.MONSTER_STILL_WINDS },
    before = { "monster.decision" },
    update = system.update,
})

return system
