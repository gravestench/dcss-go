-- Force a Xom action during a real player command to exercise rollback.
local actions = require("policy.religion.xom.actions")
local component = require("constants.component")
local events = require("ids.xom_events")

local system = {}

-- The game must restore this whole turn when the effective action fails.
function system.update(ctx, actor, elapsed_aut)
    if actor == ctx:player() and elapsed_aut > 0 then
        actions.take(ctx, actor, events.GOOD_POTION, 10)
    end
end

register.system({
    id = "religion.xom.reaction",
    scope = "active",
    query = { component.PLAYER },
    after = {
        "actor.death",
        "religion.upkeep",
    },
    update = system.update,
})

return system
