-- The player's accepted action time advances the two Volcano terrain
-- events only while that temporary floor is active. The Lua policy owns
-- source phases; the scheduler contributes no Volcano-specific rules.
local branches = require("ids.branches")
local component = require("constants.component")
local events = require("policy.world.volcano.hazard_events")

local system = {}

-- A monster action does not advance an extra copy of the floor clock.
function system.update(ctx, actor, delta)
    if actor ~= ctx:player() or delta <= 0 then
        return
    end

    local position = ctx:get(actor, component.POSITION)

    if position and ctx:level_branch(position.level_id) ==
        branches.BRANCH_VOLCANO then
        events.advance(ctx, position, delta)
    end
end

register.system({
    id = "world.volcano_hazards",
    scope = "active",
    query = {},
    after = { "world.volcano_portals" },
    before = { "actor.death" },
    update = system.update,
})

return system
