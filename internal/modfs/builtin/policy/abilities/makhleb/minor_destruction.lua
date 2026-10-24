-- Minor Destruction owns Makhleb's second-star aimed power. Its five
-- random effects share the ordinary player zap contact engine.
local abilities = require("ids.abilities")
local destruction = require("policy.abilities.makhleb.destruction")
local registry = require("policy.abilities.registry")

local minor = {}

-- Check live worship whenever the ability menu or resolver asks.
function minor.available(ctx, player)
    return destruction.available(ctx, player, 2)
end

-- The source five-cell range contracts with the current vision radius.
function minor.range(_, ctx, player)
    return destruction.range(ctx, player, 5)
end

-- One fixed HP is affordable only while at least two HP remain.
function minor.prepare(ctx, player, input)
    return destruction.prepare(ctx, player, input,
        1, 5, 40, 5, 20, 1)
end

-- The source tuple is invo 40,5,20 and this tier has no piety cost.
function minor.resolve(ctx, player, intent)
    destruction.resolve(ctx, player, intent,
        "minor", 1, 40, 5, 20, 1, 5)
end

registry.add(abilities.MAKHLEB_MINOR_DESTRUCTION, {
    name = "Minor Destruction",
    available = minor.available,
    range = minor.range,
    prepare = minor.prepare,
    resolve = minor.resolve,
})

return minor
