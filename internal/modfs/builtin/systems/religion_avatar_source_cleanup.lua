-- Ongoing god-spell effects retain an inert source actor. Remove that actor
-- after its final status, cloud, terrain change, or summon has expired so
-- wrath does not accumulate invisible actors across long games.
local avatar = require("policy.religion.wrath.avatar")

local system = {}

-- Run after the active actor's effects have had a chance to expire.
-- The owner checks actual ECS references, so scheduler order cannot
-- erase attribution while a continuing effect is still present.
function system.update(ctx)
    avatar.cleanup(ctx)
end

register.system({
    id = "religion.avatar_source.cleanup",
    scope = "active",
    query = {},
    after = { "magic.summon.expiry" },
    update = system.update,
})

return system
