-- A level transition is a generic engine event. Lua rules react to it
-- after the player has arrived and after the destination's away-time work.
-- Slime:5 currently uses it to run the source's persistent vault fixup.
local seals = require("policy.world.slime_seals")

local entry = {}

-- Entry reads saved world and player state, so revisiting a floor cannot
-- reroll generation or repeat a consumed one-time callback.
function entry.run(ctx, input)
    seals.enter(ctx, input.level_id)

    return {}
end

register.policy({
    id = "world.enter_level",
    run = entry.run,
})

return entry
