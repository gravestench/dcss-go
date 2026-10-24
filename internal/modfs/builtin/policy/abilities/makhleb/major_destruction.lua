-- Major Destruction owns Makhleb's fourth-star aimed power. It chooses
-- one of five source bolts only after its safe tracer and failure gate.
local abilities = require("ids.abilities")
local destruction = require("policy.abilities.makhleb.destruction")
local registry = require("policy.abilities.registry")

local major = {}

-- Check live worship whenever the ability menu or resolver asks.
function major.available(ctx, player)
    return destruction.available(ctx, player, 4)
end

-- LOS_MAX_RANGE is the player's current vision, including Nightstalker.
function major.range(_, ctx, player)
    return destruction.range(ctx, player, 7)
end

-- Six fixed HP must remain survivable before direction is timed.
function major.prepare(ctx, player, input)
    return destruction.prepare(ctx, player, input,
        6, 7, 60, 4, 25, 2)
end

-- The source tuple is invo 60,4,25; successful use draws 0–1 piety.
function major.resolve(ctx, player, intent)
    destruction.resolve(ctx, player, intent,
        "major", 6, 60, 4, 25, 2, 7)
end

registry.add(abilities.MAKHLEB_MAJOR_DESTRUCTION, {
    name = "Major Destruction",
    available = major.available,
    range = major.range,
    prepare = major.prepare,
    resolve = major.resolve,
})

return major
