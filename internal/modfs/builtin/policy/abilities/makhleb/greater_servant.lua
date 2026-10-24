-- Greater Servant owns Makhleb's fifth-star demon invocation. The shared
-- servant owner performs its source selection and hostile failure behavior.
local abilities = require("ids.abilities")
local registry = require("policy.abilities.registry")
local servant = require("policy.abilities.makhleb.servant")

local greater = {}

-- Live worship and No Love decide whether the menu may offer this power.
function greater.available(ctx, player)
    return servant.available(ctx, player, 5)
end

-- Ten fixed HP must leave at least one point before a turn begins.
function greater.prepare(ctx, player)
    return servant.prepare(ctx, player, 10)
end

-- The source failure tuple is 90,2,5. Generic piety base five draws
-- five through eight points on every attempted demon, including hostility.
function greater.resolve(ctx, player)
    servant.resolve(ctx, player, "greater", 10, 5, 90, 2, 5)
end

registry.add(abilities.MAKHLEB_GREATER_SERVANT, {
    name = "Greater Servant of Makhleb",
    available = greater.available,
    prepare = greater.prepare,
    resolve = greater.resolve,
})

return greater
