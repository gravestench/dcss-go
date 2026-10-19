-- Theory of operation: the caster's saved aura decays on its actions.
-- Every noise and action check derives the current field from the timer
-- and live position, so movement and save/restore need no cached cell map.
local component = require("constants.component")
local silence = require("policy.world.silence")

local system = {}

-- Remove expired fields before the monster chooses its next spell.
function system.update(ctx, monster, elapsed_aut)
    silence.tick(ctx, monster, elapsed_aut)
end

register.system({
    id = "world.monster_silence.tick",
    scope = "active",
    query = { component.MONSTER_SILENCE },
    before = { "monster.decision" },
    update = system.update,
})

return system
