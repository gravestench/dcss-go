-- Departures resolve after movement and death, so a monster cannot leave
-- from its old cell or turn a lethal hit into a no-corpse hard reset.
local component = require("constants.component")
local departure = require("policy.ai.pacified_departure")

local system = {}

-- Only pacified actors are queried; completion checks their current cell
-- and distance again because movement may have failed this action.
function system.update(ctx, monster)
    departure.complete(ctx, monster)
end

register.system({
    id = "monster.pacified_departure",
    scope = "active",
    query = { component.ELYVILON_PACIFIED },
    after = { "actor.death" },
    before = { "character.training" },
    update = system.update,
})

return system
