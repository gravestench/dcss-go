-- Boris's first death reopens his active unique claim and records that he
-- has been killed. A later new-level population pass owns his 1-in-6
-- replacement draw; death itself never creates another Boris beside him.
local death_hooks = require("policy.combat.death_hooks")
local history = require("policy.population.unique_history")
local monsters = require("ids.monsters")

local boris = {}

-- Only an actual Boris death changes his run state. Transit and pacified
-- departures are separate flows and never enter actor.death here.
function boris.on_death(ctx, actor, definition)
    if definition.id ~= monsters.MONS_BORIS then
        return false
    end

    history.release(ctx, monsters.MONS_BORIS)

    return false
end

death_hooks.add("unique.boris", boris.on_death)

return boris
