local component = require("constants.component")
local sleep = require("policy.character.sleep")

local system = {}

function system.update(ctx, entity, aut)
    sleep.tick(ctx, entity, aut)
end

register.system({
    id = "magic.player_sleep.tick",
    scope = "active",
    query = { component.PLAYER_SLEEP },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
