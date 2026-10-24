-- Xom's saved stair durations count down after the player has moved or
-- tried to climb, so a turn sees the full timer it started with.
local component = require("constants.component")
local repel = require("policy.religion.xom.stair_repel")

local system = {}

-- Only completed player actions consume these player-owned durations.
function system.update(ctx, actor, elapsed_aut)
    if actor == ctx:player() then
        repel.tick(ctx, actor, elapsed_aut)
    end
end

register.system({
    id = "religion.xom_stair_repel",
    scope = "active",
    query = { component.PLAYER },
    after = { "world.movement" },
    before = { "religion.xom.reaction" },
    update = system.update,
})

return system
