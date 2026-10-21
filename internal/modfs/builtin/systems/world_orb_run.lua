-- Player actions after Orb pickup periodically place source escape
-- defenders. This system owns no timer; the saved aut clock and chapter do.
local run = require("policy.character.orb_run")

local system = {}

-- Run after stair travel and pickup so an Orb collected on this action can
-- start the escape clock before the next 50-aut boundary check.
function system.update(ctx, actor, elapsed_aut)
    run.update(ctx, actor, elapsed_aut)
end

register.system({
    id = "world.orb_run",
    scope = "active",
    query = {},
    after = { "world.stairs", "item.pickup" },
    update = system.update,
})

return system
