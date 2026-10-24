-- Divine Vigour's saved player clock ages after ordinary duration effects
-- and before regeneration reads its current HP and MP maxima.
local component = require("constants.component")
local vigour = require("policy.religion.elyvilon.vigour")

local system = {}

-- An orphan status is a save error; active turns touch only the player.
function system.update(ctx, entity, aut)
    if entity == ctx:player() then
        vigour.tick(ctx, entity, aut)
    end
end

register.system({
    id = "religion.elyvilon_vigour.tick",
    scope = "active",
    query = { component.ELYVILON_VIGOUR },
    after = { "status.duration" },
    before = { "status.regeneration" },
    update = system.update,
})

return system
