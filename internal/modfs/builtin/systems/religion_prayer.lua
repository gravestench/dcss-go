-- Theory of operation: a confirmed prayer intent is the sole timed path
-- that changes worship at an altar. The Lua owner validates the saved altar
-- again, joins its god, and identifies unknown altars for later visits.
local component = require("constants.component")
local intents = require("constants.intent")
local prayer = require("policy.religion.prayer")

local system = {}

-- Resolve only the player's accepted prayer; other actor intents are left to
-- their own systems and cannot mutate the player's god accidentally.
function system.update(ctx, actor)
    if actor ~= ctx:player() then
        return
    end

    local intent = ctx:get(actor, component.INTENT)

    if not intent or intent.kind ~= intents.PRAYER then
        return
    end

    local message = prayer.resolve(ctx, actor, intent)

    ctx:emit("religion", message)
end

register.system({
    id = "religion.prayer",
    scope = "active",
    query = {},
    after = { "monster.decision" },
    update = system.update,
})

return system
